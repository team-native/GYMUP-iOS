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
                title: "비교 보기",
                onBack: dismiss.callAsFunction,
                actionTitle: selection == nil ? nil : "초기화",
                action: resetComparison
            )
            if let selectedRecords {
                comparisonContent(selectedRecords)
            } else {
                emptyContent
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: store.records.map(\.id)) { _, _ in
            resetComparison()
        }
    }
}

private extension HistoryComparisonView {
    private func comparisonContent(_ records: (before: WorkoutRecord, after: WorkoutRecord)) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                comparisonHeading
                photoPair(records)
                comparisonSummary(records)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
    }

    private var comparisonHeading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("나의 변화")
                .font(GymupTypography.title)
                .foregroundStyle(GymupColors.primaryText)
            Text("운동 기록을 선택해 사진과 변화를 비교해요.")
                .font(GymupTypography.callout)
                .foregroundStyle(GymupColors.secondaryText)
        }
    }

    private func photoPair(_ records: (before: WorkoutRecord, after: WorkoutRecord)) -> some View {
        HStack(alignment: .top, spacing: 8) {
            comparisonColumn(record: records.before, badge: "BEFORE", isBefore: true)
            comparisonColumn(record: records.after, badge: "AFTER", isBefore: false)
        }
    }

    private func comparisonColumn(record: WorkoutRecord, badge: String, isBefore: Bool) -> some View {
        let accessibleSide = isBefore ? "비교 전" : "비교 후"
        let accessibleDate = HistoryDateText.string(record.date, format: "yyyy년 M월 d일")

        return VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    HistoryWorkoutPhoto(assetName: record.photoAssetName)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.72)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    VStack(alignment: .leading, spacing: 5) {
                        Text(badge)
                            .font(GymupTypography.uiCaption)
                            .tracking(0.8)
                            .foregroundStyle(.white.opacity(0.75))
                        Text(HistoryDateText.string(record.date, format: "M월 d일"))
                            .font(GymupTypography.uiStrong)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .frame(height: 276)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(accessibleSide) 사진, \(accessibleDate), \(record.routineName)")

            recordPicker(record: record, isBefore: isBefore)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func recordPicker(record: WorkoutRecord, isBefore: Bool) -> some View {
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
            VStack(alignment: .leading, spacing: 5) {
                Text(record.routineName)
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(HistoryDateText.string(record.date, format: "yyyy.MM.dd"))
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Text("기록 변경")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.accent)
                .frame(minHeight: 24, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .accessibilityLabel(title)
        .accessibilityValue("\(record.routineName), \(HistoryDateText.string(record.date, format: "yyyy년 M월 d일"))")
        .accessibilityHint("비교할 운동 기록을 변경합니다")
        .accessibilityIdentifier(isBefore ? "history.comparison.beforePicker" : "history.comparison.afterPicker")
        .disabled(choices.isEmpty)
    }

    private func comparisonSummary(_ records: (before: WorkoutRecord, after: WorkoutRecord)) -> some View {
        HistoryCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("운동 기록 비교")
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                    Spacer(minLength: 8)
                    Text(comparisonPeriod(from: records.before.date, to: records.after.date))
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                comparisonMetric(
                    title: "운동 시간",
                    before: "\(records.before.durationMinutes)분",
                    after: "\(records.after.durationMinutes)분"
                )
                comparisonMetric(
                    title: "세트 수",
                    before: "\(records.before.setCount)세트",
                    after: "\(records.after.setCount)세트"
                )
                comparisonMetric(
                    title: "운동 볼륨",
                    before: "\(records.before.volumeKilograms.formatted())kg",
                    after: "\(records.after.volumeKilograms.formatted())kg"
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("history.comparison.summary")
    }

    private func comparisonMetric(title: String, before: String, after: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
            Spacer(minLength: 4)
            Text(before)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.primaryText)
                .lineLimit(1)
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(GymupColors.accent)
                .accessibilityHidden(true)
            Text(after)
                .font(GymupTypography.uiStrong)
                .foregroundStyle(GymupColors.primaryText)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), 비교 전 \(before), 비교 후 \(after)")
    }

    private var emptyContent: some View {
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
    }

    private var comparisonData: HistoryComparisonData {
        HistoryComparisonData(records: store.records)
    }

    private var selectedRecords: (before: WorkoutRecord, after: WorkoutRecord)? {
        guard let selection else { return nil }
        let before = comparisonData.record(with: selection.beforeRecordID)
        let after = comparisonData.record(with: selection.afterRecordID)
        guard let before, let after else { return nil }
        return (before, after)
    }

    private func select(_ record: WorkoutRecord, isBefore: Bool) {
        guard let selection else { return }
        let beforeID = isBefore ? record.id : selection.beforeRecordID
        let afterID = isBefore ? selection.afterRecordID : record.id
        self.selection = comparisonData.selection(beforeRecordID: beforeID, afterRecordID: afterID)
    }

    private func resetComparison() {
        selection = comparisonData.initialSelection(preferredAfterRecordID: initialRecordID)
    }

    private func comparisonPeriod(from beforeDate: Date, to afterDate: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: beforeDate, to: afterDate).day ?? 0
        return days == 0 ? "같은 날" : "\(days)일 간격"
    }
}

#Preview {
    HistoryComparisonView(
        store: HistoryStore(records: HistoryListSampleData.records),
        initialRecordID: HistoryListSampleData.records.first?.id
    )
        .preferredColorScheme(.dark)
}
