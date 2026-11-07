import SwiftUI

struct HistoryView: View {
    let store: HistoryStore
    @Bindable private var listViewModel: HistoryListViewModel
    let workoutDetailService: WorkoutDetailReading?
    let onOpenRoutines: () -> Void
    let onComparisonPresented: (Bool) -> Void
    let onGrowthPresented: (Bool) -> Void
    @State private var path: [HistoryRoute] = []
    @State private var selectedMonth: Date
    @State private var selectedDate: Date
    @State private var visibleWorkoutID: String?
    @State private var hasManuallySelectedDate = false

    @MainActor
    init(
        store: HistoryStore,
        listViewModel: HistoryListViewModel? = nil,
        workoutDetailService: WorkoutDetailReading? = nil,
        onOpenRoutines: @escaping () -> Void = {},
        onComparisonPresented: @escaping (Bool) -> Void = { _ in },
        onGrowthPresented: @escaping (Bool) -> Void = { _ in }
    ) {
        self.store = store
        _listViewModel = Bindable(wrappedValue: listViewModel ?? HistoryListViewModel(service: nil, routineStore: nil))
        self.workoutDetailService = workoutDetailService
        self.onOpenRoutines = onOpenRoutines
        self.onComparisonPresented = onComparisonPresented
        self.onGrowthPresented = onGrowthPresented
        let initialRecord = store.records.first
        let initialDate = initialRecord?.date ?? .now
        let initialMonth = Calendar.current.dateInterval(of: .month, for: initialDate)?.start ?? initialDate
        _selectedMonth = State(initialValue: initialMonth)
        _selectedDate = State(initialValue: initialDate)
        _visibleWorkoutID = State(initialValue: initialRecord.map { "local-\($0.id.uuidString)" })
    }

    var body: some View {
        NavigationStack(path: $path) {
            historyList
                .navigationDestination(for: HistoryRoute.self) { route in
                    destination(for: route)
                }
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(GymupColors.canvas.ignoresSafeArea())
        .onAppear {
            onComparisonPresented(isComparisonPresented)
            onGrowthPresented(path.contains(.growth))
            Task { await listViewModel.refresh() }
        }
        .onChange(of: path) { _, _ in
            onComparisonPresented(isComparisonPresented)
            onGrowthPresented(path.contains(.growth))
        }
    }

    private var historyList: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if allRecords.isEmpty {
                        emptyHistoryContent
                            .frame(minHeight: max(geometry.size.height - 36, 0))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 28)
                    } else {
                        populatedHistoryContent(using: proxy)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 28)
                    }
                }
                .scrollPosition(id: $visibleWorkoutID, anchor: .top)
                .background(GymupColors.canvas.ignoresSafeArea())
                .onChange(of: store.records.map(\.id)) { _, _ in
                    selectLatestRecord()
                }
                .onChange(of: listViewModel.serverRecords.map(\.id)) { _, _ in
                    guard !hasManuallySelectedDate else { return }
                    selectLatestRecord()
                }
            }
        }
    }

    private var emptyHistoryContent: some View {
        VStack(spacing: 0) {
            header(showsCalendarButton: false)
            if listViewModel.isLoading {
                Spacer(minLength: 24)
                ProgressView()
                    .tint(GymupColors.accent)
                    .accessibilityLabel("운동 기록 불러오는 중")
                Spacer(minLength: 24)
            } else {
                Spacer(minLength: 24)
                HistoryEmptyContent(onOpenRoutines: onOpenRoutines)
                Spacer(minLength: 24)
            }
            if let errorMessage = listViewModel.errorMessage {
                HistoryServerErrorNotice(message: errorMessage) {
                    Task { await listViewModel.retry() }
                }
                    .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func populatedHistoryContent(using proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            header(showsCalendarButton: !store.records.isEmpty)
            if listViewModel.isLoading {
                ProgressView()
                    .tint(GymupColors.accent)
                    .frame(maxWidth: .infinity, minHeight: 28)
                    .accessibilityLabel("운동 기록 새로고침 중")
            }
            if let errorMessage = listViewModel.errorMessage {
                HistoryServerErrorNotice(message: errorMessage) {
                    Task { await listViewModel.retry() }
                }
            }
            HistoryWeekSelector(
                dates: weekDates,
                selectedDate: selectedDate,
                workoutDates: monthRecords.map(\.date),
                onSelect: { select($0, using: proxy) }
            )
            HistoryMonthlySummary(
                count: monthRecords.count,
                selectedMonth: selectedMonth,
                duration: formattedDuration,
                volume: formattedVolume,
                monthOptions: monthOptions,
                onSelectMonth: selectMonth
            )
            if !monthRecords.isEmpty {
                workoutSection
            }
            if !store.records.isEmpty {
                growthLink
            }
        }
    }

    private var workoutSection: some View {
        VStack(spacing: 8) {
            ForEach(monthRecords) { record in
                Button {
                    path.append(record.detailRoute)
                } label: {
                    HistoryWorkoutRow(record: record, isServerSummary: record.serverWorkout != nil)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(record.detailAccessibilityIdentifier)
                .id(record.id)
            }
        }
        .scrollTargetLayout()
    }

    private var growthLink: some View {
        Button {
            path.append(.growth)
        } label: {
            Text("기록이 있을 때 화면 보기")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.accent)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("history.openGrowth")
    }

    @ViewBuilder
    private func destination(for route: HistoryRoute) -> some View {
        switch route {
        case let .detail(id):
            if let record = store.record(with: id)
                ?? HistoryListSampleData.record(with: id)
                ?? HistorySampleData.record(with: id) {
                HistoryDetailView(record: record, onOpenAlbum: { path.append(.album) })
            }
        case let .serverDetail(workout):
            HistoryServerWorkoutDetailScreen(workout: workout, service: workoutDetailService)
        case .calendar:
            HistoryCalendarView(store: store, onOpenDetail: { path.append(.detail($0)) })
        case .growth:
            HistoryGrowthView(store: store)
        case .album:
            HistoryAlbumView(
                store: store,
                onOpenRoutines: onOpenRoutines,
                onOpenDetail: { path.append(.detail($0)) },
                onCompare: { path.append(.comparison($0)) }
            )
        case let .comparison(recordID):
            HistoryComparisonView(store: store, initialRecordID: recordID)
        }
    }
}

private extension HistoryView {
    var isComparisonPresented: Bool {
        guard let route = path.last else { return false }
        if case .comparison = route { return true }
        return false
    }
}

private extension HistoryView {
    var monthRecords: [HistoryListEntry] {
        guard let month = Calendar.current.dateInterval(of: .month, for: selectedMonth) else { return [] }
        return allRecords.filter { $0.date >= month.start && $0.date < month.end }
    }

    var allRecords: [HistoryListEntry] {
        listViewModel.entries(localRecords: store.records)
    }

    var formattedDuration: String {
        let totalMinutes = monthRecords.reduce(0) { $0 + $1.durationMinutes }
        return "\(totalMinutes / 60)H \(totalMinutes % 60)M"
    }

    var formattedVolume: String {
        let totalKilograms = monthRecords.reduce(0) { $0 + $1.volumeKilograms }
        return String(format: "%.1f", Double(totalKilograms) / 1_000)
    }

    func select(_ date: Date, using proxy: ScrollViewProxy) {
        hasManuallySelectedDate = true
        selectedDate = date
        guard let record = monthRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            visibleWorkoutID = record.id
            proxy.scrollTo(record.id, anchor: .top)
        }
    }

    func selectMonth(_ month: Date) {
        hasManuallySelectedDate = true
        selectedMonth = month
        let monthRecords = allRecords.filter { record in
            guard let interval = Calendar.current.dateInterval(of: .month, for: month) else { return false }
            return record.date >= interval.start && record.date < interval.end
        }
        selectedDate = monthRecords.first?.date ?? month
        visibleWorkoutID = monthRecords.first?.id
    }

    func selectLatestRecord() {
        guard let latestRecord = allRecords.first else { return }
        selectedMonth = Calendar.current.dateInterval(of: .month, for: latestRecord.date)?.start
            ?? latestRecord.date
        selectedDate = latestRecord.date
        visibleWorkoutID = latestRecord.id
    }

    var monthOptions: [Date] {
        let calendar = Calendar.current
        let selectedMonthStart = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonthStart) ?? selectedMonthStart
        let recordMonths = allRecords.compactMap { calendar.dateInterval(of: .month, for: $0.date)?.start }
        return Array(Set(recordMonths + [selectedMonthStart, previousMonth])).sorted(by: >)
    }

    var weekDates: [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysFromMonday = (weekday + 5) % 7
        let start = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate) ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    func header(showsCalendarButton: Bool) -> some View {
        HStack(alignment: .center) {
            Text("기록")
                .font(GymupTypography.homeTitle)
                .tracking(-0.43)
                .foregroundStyle(GymupColors.primaryText)
            Spacer()
            if showsCalendarButton {
                Button {
                    path.append(.calendar)
                } label: {
                    Image("H1IconCalendar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("월간 캘린더")
                .accessibilityIdentifier("history.openCalendar")
            }
        }
        .frame(height: 48)
    }

    func accessibilityLabel(for date: Date, hasWorkout: Bool) -> String {
        let day = date.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).month().day().weekday(.wide))
        return hasWorkout ? "\(day), 운동 기록 있음" : day
    }
}

#Preview {
    HistoryView(store: HistoryStore())
        .preferredColorScheme(.dark)
}

#Preview("G1 기록 목록") {
    HistoryView(store: HistoryStore(records: HistoryListSampleData.records))
        .preferredColorScheme(.dark)
}
