import SwiftUI

struct HistoryComparisonView: View {
    let store: HistoryStore
    let initialRecordID: UUID?

    @Environment(\.dismiss) private var dismiss
    @State private var selection: HistoryComparisonSelection?

    @MainActor
    init(store: HistoryStore, initialRecordID: UUID? = nil) {
        self.store = store
        self.initialRecordID = initialRecordID
        let initialSelection = HistoryComparisonData(records: store.records)
            .initialSelection(preferredAfterRecordID: initialRecordID)
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        VStack(spacing: 0) {
            HistoryNavigationBar(
                title: "비교",
                onBack: dismiss.callAsFunction,
                actionTitle: canReset ? "초기화" : nil,
                action: resetComparison
            )

            if let selectedRecords {
                comparisonContent(selectedRecords)
            } else {
                emptyContent
            }
        }
        .background(HistoryComparisonPalette.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: store.records.map(\.id)) { _, _ in
            resetComparison()
        }
    }
}

private extension HistoryComparisonView {
    var canReset: Bool {
        guard let selection else { return false }
        return selection != comparisonData.initialSelection(preferredAfterRecordID: initialRecordID)
    }

    func comparisonContent(_ records: (before: WorkoutRecord, after: WorkoutRecord)) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                versionBadge
                    .padding(.top, 12)

                photoPair(records)
                    .padding(.top, 12)

                comparisonSummary(records)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .accessibilityIdentifier("history.comparison.content")
    }

    var versionBadge: some View {
        Text("V2 · MVP 제외")
            .font(GymupTypography.uiCaption)
            .foregroundStyle(HistoryComparisonPalette.mutedText)
            .padding(.horizontal, 8)
            .frame(minHeight: 20)
            .background(HistoryComparisonPalette.badge, in: Capsule())
            .accessibilityLabel("V2, MVP 제외")
    }

    func photoPair(_ records: (before: WorkoutRecord, after: WorkoutRecord)) -> some View {
        HStack(alignment: .top, spacing: 4) {
            comparisonColumn(record: records.before, isBefore: true)
            comparisonColumn(record: records.after, isBefore: false)
        }
    }

    func comparisonColumn(record: WorkoutRecord, isBefore: Bool) -> some View {
        let side = isBefore ? "비교 전" : "비교 후"
        let date = HistoryDateText.string(record.date, format: "yyyy년 M월 d일")

        return VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                HistoryWorkoutPhoto(assetName: record.photoAssetName)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .aspectRatio(0.55, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(side) 사진, \(date), \(record.routineName)")
            .accessibilityAddTraits(.isImage)

            recordPicker(record: record, isBefore: isBefore)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    func recordPicker(record: WorkoutRecord, isBefore: Bool) -> some View {
        let choices = isBefore
            ? comparisonData.beforeChoices(forAfterRecordID: selection?.afterRecordID ?? record.id)
            : comparisonData.afterChoices(forBeforeRecordID: selection?.beforeRecordID ?? record.id)
        let title = isBefore ? "비교 전 기록 선택" : "비교 후 기록 선택"

        return Menu {
            ForEach(choices) { choice in
                Button {
                    select(choice, isBefore: isBefore)
                } label: {
                    Text("\(HistoryDateText.string(choice.date, format: "M월 d일")) · \(choice.routineName)")
                }
            }
        } label: {
            Text(HistoryDateText.string(record.date, format: "M월 d일"))
                .font(GymupTypography.uiCaption)
                .foregroundStyle(HistoryComparisonPalette.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue("\(record.routineName), \(HistoryDateText.string(record.date, format: "yyyy년 M월 d일"))")
        .accessibilityHint("비교할 운동 기록을 변경합니다")
        .accessibilityIdentifier(isBefore ? "history.comparison.beforePicker" : "history.comparison.afterPicker")
        .disabled(choices.isEmpty)
    }

    func comparisonSummary(_ records: (before: WorkoutRecord, after: WorkoutRecord)) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(comparisonPeriod(from: records.before.date, to: records.after.date))
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(HistoryComparisonPalette.mutedText)
                    .accessibilityLabel("운동 기록 간격, \(comparisonPeriod(from: records.before.date, to: records.after.date))")

                Spacer(minLength: 8)

                Text("Growth 12 → 67")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(HistoryComparisonPalette.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel("Growth 12에서 67")
            }

            HistoryComparisonTrack()
                .accessibilityIdentifier("history.comparison.growthTrack")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("history.comparison.summary")
    }

    var emptyContent: some View {
        let hasNoRecords = store.records.isEmpty
        let title = hasNoRecords ? "비교할 운동 사진이 없어요" : "사진을 한 장 더 남겨주세요"
        let description = hasNoRecords
            ? "운동을 완료하고 사진을 남기면 비교할 수 있어요."
            : "두 번 이상의 운동 기록이 있어야 비교할 수 있어요."

        return VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(GymupColors.secondaryText)
                .accessibilityHidden(true)
            Text(title)
                .font(GymupTypography.uiStrong)
                .foregroundStyle(GymupColors.primaryText)
                .multilineTextAlignment(.center)
            Text(description)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(24)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("history.comparison.emptyState")
    }

    var comparisonData: HistoryComparisonData {
        HistoryComparisonData(records: store.records)
    }

    var selectedRecords: (before: WorkoutRecord, after: WorkoutRecord)? {
        guard let selection else { return nil }
        let before = comparisonData.record(with: selection.beforeRecordID)
        let after = comparisonData.record(with: selection.afterRecordID)
        guard let before, let after else { return nil }
        return (before, after)
    }

    func select(_ record: WorkoutRecord, isBefore: Bool) {
        guard let selection else { return }
        let beforeID = isBefore ? record.id : selection.beforeRecordID
        let afterID = isBefore ? selection.afterRecordID : record.id
        self.selection = comparisonData.selection(beforeRecordID: beforeID, afterRecordID: afterID)
    }

    func resetComparison() {
        selection = comparisonData.initialSelection(preferredAfterRecordID: initialRecordID)
    }

    func comparisonPeriod(from beforeDate: Date, to afterDate: Date) -> String {
        let days = max(0, Calendar.current.dateComponents([.day], from: beforeDate, to: afterDate).day ?? 0)
        let weeks = days / 7
        return weeks > 0 ? "\(weeks)주 차이" : "\(days)일 차이"
    }
}

private struct HistoryComparisonTrack: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Capsule()
                    .fill(HistoryComparisonPalette.track)
                    .frame(height: 2)

                Circle()
                    .fill(HistoryComparisonPalette.accent)
                    .frame(width: 12, height: 12)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: 20)
        .accessibilityHidden(true)
    }
}

private enum HistoryComparisonPalette {
    static let canvas = Color(red: 11.0 / 255.0, green: 11.0 / 255.0, blue: 13.0 / 255.0)
    static let badge = Color(red: 31.0 / 255.0, green: 31.0 / 255.0, blue: 33.0 / 255.0)
    static let mutedText = Color(red: 161.0 / 255.0, green: 161.0 / 255.0, blue: 170.0 / 255.0)
    static let primaryText = Color.white
    static let track = Color(red: 48.0 / 255.0, green: 48.0 / 255.0, blue: 52.0 / 255.0)
    static let accent = Color(red: 1, green: 18.0 / 255.0, blue: 22.0 / 255.0)
}

#Preview {
    HistoryComparisonView(
        store: HistoryStore(records: HistoryComparisonPreviewData.records),
        initialRecordID: HistoryComparisonPreviewData.records.last?.id
    )
    .preferredColorScheme(.dark)
}

private enum HistoryComparisonPreviewData {
    static let records: [WorkoutRecord] = {
        let samples = HistoryListSampleData.records
        guard samples.count >= 2 else { return samples }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        guard
            let beforeDate = calendar.date(from: DateComponents(year: 2025, month: 7, day: 12)),
            let afterDate = calendar.date(from: DateComponents(year: 2025, month: 10, day: 11))
        else {
            return samples
        }

        return [
            replacingDate(of: samples[1], with: beforeDate),
            replacingDate(of: samples[0], with: afterDate)
        ]
    }()

    private static func replacingDate(of record: WorkoutRecord, with date: Date) -> WorkoutRecord {
        WorkoutRecord(
            id: record.id,
            date: date,
            routineName: record.routineName,
            category: record.category,
            durationMinutes: record.durationMinutes,
            setCount: record.setCount,
            volumeKilograms: record.volumeKilograms,
            growth: record.growth,
            photoAssetName: record.photoAssetName,
            exercises: record.exercises
        )
    }
}
