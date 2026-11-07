import XCTest
@testable import GYMUP

final class HistoryListViewModelTests: XCTestCase {
    @MainActor
    func testRefreshUsesUTCDateRangeAndFollowsNextCursor() async throws {
        let first = workout(
            id: "workout-first",
            date: "2026-11-06T08:00:00Z",
            routineName: "Routine First",
            duration: 1_800,
            totalSets: 8,
            volume: 2_400
        )
        let second = workout(
            id: "workout-second",
            date: "2026-11-05T08:00:00Z",
            routineName: "Routine Second",
            duration: 1_200,
            totalSets: 5,
            volume: 1_250
        )
        let service = WorkoutListServiceStub([
            .success(ListWorkoutsResponse(items: [first], nextCursor: "next-page")),
            .success(ListWorkoutsResponse(items: [second], nextCursor: nil))
        ])
        let routineStore = makeRoutineStore()
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-11-06T17:30:00Z"))
        let viewModel = HistoryListViewModel(
            service: service,
            routineStore: routineStore,
            nowProvider: { now }
        )

        await viewModel.refresh()

        XCTAssertEqual(service.requests.count, 2)
        XCTAssertNil(service.requests[0].cursor)
        XCTAssertEqual(service.requests[1].cursor, "next-page")
        XCTAssertEqual(service.requests[0].size, 100)
        XCTAssertEqual(service.requests[0].from, "1970-01-01")
        XCTAssertEqual(service.requests[0].endDate, "2026-11-06")
        XCTAssertEqual(service.requests[0].routineId, "server-routine-1")
        XCTAssertEqual(viewModel.serverRecords.map(\.id), ["workout-first", "workout-second"])
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testNullNextCursorEndsPagination() async {
        let service = WorkoutListServiceStub([
            .success(ListWorkoutsResponse(items: [workout()], nextCursor: nil))
        ])
        let viewModel = HistoryListViewModel(service: service, routineStore: makeRoutineStore())

        await viewModel.refresh()

        XCTAssertEqual(service.requests.count, 1)
        XCTAssertEqual(viewModel.serverRecords.map(\.id), ["workout-1"])
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testResponseMappingPreservesOffsetNameAndSummaryUnits() throws {
        let item = workout(
            id: "workout-offset",
            date: "2026-11-07T00:30:00+03:00",
            routineName: "UPPER A / 胸",
            duration: 1_801,
            totalSets: 4,
            volume: 1_234.6
        )
        let parsed = try XCTUnwrap(HistoryServerWorkout(response: item))
        let expectedDate = try XCTUnwrap(ISO8601DateFormatter().date(from: item.date))
        let entry = HistoryListEntry(serverRecord: parsed)

        XCTAssertEqual(parsed.date, expectedDate)
        XCTAssertEqual(HistoryDateText.string(parsed.date, format: "yyyy-MM-dd"),
                       HistoryDateText.string(expectedDate, format: "yyyy-MM-dd"))
        XCTAssertEqual(parsed.routineName, "UPPER A / 胸")
        XCTAssertEqual(parsed.durationMinutes, 31)
        XCTAssertEqual(parsed.setCount, 4)
        XCTAssertEqual(parsed.volumeKilograms, 1_235)
        XCTAssertNil(entry.localRecordID)
        XCTAssertNil(entry.personalRecordCount)
        XCTAssertEqual(entry.routineName, "UPPER A / 胸")
    }

    @MainActor
    func testDateOnlyResponseUsesTheSpecifiedLocalCalendarDay() throws {
        let item = workout(date: "2026-11-07")
        let parsed = try XCTUnwrap(HistoryServerWorkout(response: item))
        let components = Calendar.current.dateComponents([.year, .month, .day], from: parsed.date)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 11)
        XCTAssertEqual(components.day, 7)
    }

    @MainActor
    func testFailureRetainsLocalAndPreviousServerRowsAndRetryRefreshes() async throws {
        let localRecord = try XCTUnwrap(HistorySampleData.records.first)
        let localStore = HistoryStore(records: [localRecord])
        let serverRecord = workout(id: "server-before-retry")
        let retryRecord = workout(id: "server-after-retry")
        let serverDetail = ServerErrorDetail(code: "SERVER_ERROR", message: "temporary server failure")
        let service = WorkoutListServiceStub([
            .success(ListWorkoutsResponse(items: [serverRecord], nextCursor: nil)),
            .failure(.server(statusCode: 503, detail: serverDetail)),
            .success(ListWorkoutsResponse(items: [retryRecord], nextCursor: nil))
        ])
        let viewModel = HistoryListViewModel(service: service, routineStore: makeRoutineStore())

        await viewModel.refresh()
        await viewModel.refresh()

        XCTAssertEqual(viewModel.errorMessage, "temporary server failure")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.serverRecords.map(\.id), ["server-before-retry"])
        XCTAssertTrue(viewModel.entries(localRecords: localStore.records).contains {
            $0.localRecordID == localRecord.id
        })

        await viewModel.retry()

        let entries = viewModel.entries(localRecords: localStore.records)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.serverRecords.map(\.id), ["server-after-retry"])
        XCTAssertTrue(entries.contains { $0.localRecordID == localRecord.id })
        XCTAssertTrue(entries.contains { $0.id == "server-server-after-retry" && $0.localRecordID == nil })
        XCTAssertEqual(entries.count, 2)
    }

    @MainActor
    private func makeRoutineStore() -> RoutineStore {
        let store = RoutineStore(defaults: nil)
        XCTAssertTrue(store.storeServerRoutineID("server-routine-1", for: "upper-a"))
        return store
    }

    private func workout(
        id: String = "workout-1",
        date: String = "2026-11-06T08:00:00Z",
        routineName: String = "UPPER A",
        duration: Int = 1_800,
        totalSets: Int = 8,
        volume: Double = 2_400
    ) -> WorkoutListItem {
        WorkoutListItem(
            workoutId: id,
            date: date,
            routineName: routineName,
            duration: duration,
            totalSets: totalSets,
            volume: volume
        )
    }
}

@MainActor
private final class WorkoutListServiceStub: WorkoutListReading {
    private var responses: [Result<ListWorkoutsResponse, APIClientError>]
    private(set) var requests: [ListWorkoutsQuery] = []

    init(_ responses: [Result<ListWorkoutsResponse, APIClientError>]) {
        self.responses = responses
    }

    func list(_ query: ListWorkoutsQuery) async throws -> ListWorkoutsResponse {
        requests.append(query)
        guard !responses.isEmpty else { throw APIClientError.invalidResponse }
        return try responses.removeFirst().get()
    }
}
