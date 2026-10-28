import SwiftUI

struct HistoryGrowthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMetric: HistoryGrowthMetric = .maxWeight
    @State private var selectedExercise = ""
    @State private var selectedRange: HistoryGrowthRange = .twelveWeeks
    @State private var selectedPointDate: Date?

    private let store: HistoryStore
    private let anchorDate: Date
    private let sampleDataOverride: [HistoryGrowthDataPoint]?

    @MainActor
    init(store: HistoryStore? = nil, anchorDate: Date = .now, sampleDataOverride: [HistoryGrowthDataPoint]? = nil) {
        self.store = store ?? HistoryStore()
        self.anchorDate = anchorDate
        self.sampleDataOverride = sampleDataOverride
    }

    var body: some View {
        VStack(spacing: 0) {
            HistoryNavigationBar(title: "성장 그래프", onBack: dismiss.callAsFunction)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    exercisePicker
                    metricPicker
                    if chartAvailability != .empty {
                        featuredMetric
                    }
                    chart
                    rangePicker
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { if selectedExercise.isEmpty { selectedExercise = exercises.first ?? "" } }
    }

    private var exercisePicker: some View {
        Menu {
            ForEach(exercises, id: \.self) { exercise in
                Button(exercise) { selectedExercise = exercise }
            }
        } label: {
            HStack(spacing: 8) {
                Text(selectedExercise.isEmpty ? "운동 기록 없음" : selectedExercise)
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(GymupColors.secondaryText)
                Spacer()
                Text("종목 선택")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 14)
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("운동 종목 선택, \(selectedExercise)")
        .accessibilityIdentifier("history.growth.exercise")
    }

    private var metricPicker: some View {
        HStack(spacing: 6) {
            ForEach(HistoryGrowthMetric.allCases) { metric in
                let isSelected = selectedMetric == metric
                Button {
                    selectedMetric = metric
                } label: {
                    Text(metric.rawValue)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(isSelected ? .white : GymupColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(isSelected ? GymupColors.accent : GymupColors.surface, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("history.growth.metric.\(metric.id)")
                .accessibilityLabel(metric.rawValue)
            }
        }
        .accessibilityLabel("성장 지표 선택")
    }

    private var featuredMetric: some View {
        Group {
            if let selectedPoint {
                HistoryCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(selectedMetric.rawValue) · \(HistoryDateText.string(selectedPoint.date, format: "M월 d일"))")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(formattedValue(selectedPoint.value))
                                .font(GymupTypography.growthScore)
                                .foregroundStyle(GymupColors.primaryText)
                            Text(selectedMetric.unit)
                                .font(GymupTypography.growthScoreUnit)
                                .foregroundStyle(GymupColors.secondaryText)
                        }
                        HStack(spacing: 5) {
                            Image(systemName: changeIndicatorSymbol)
                                .font(.system(size: 10, weight: .bold))
                            Text(changeDescription)
                                .font(GymupTypography.uiCaption)
                        }
                        .foregroundStyle(changeIndicatorColor)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(featuredMetricAccessibilityLabel)
            }
        }
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HistorySectionTitle(title: "기록 변화", subtitle: selectedExercise)
            switch chartAvailability {
            case .empty:
                HistoryCard {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(GymupColors.secondaryText)
                            .accessibilityHidden(true)
                        Text("이 종목의 기록이 없어요")
                            .font(GymupTypography.uiStrong)
                            .foregroundStyle(GymupColors.primaryText)
                        Text("운동 기록을 추가하면 성장 그래프가 표시됩니다.")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, minHeight: 156)
                    .multilineTextAlignment(.center)
                }
                .accessibilityIdentifier("history.growth.empty")
            case .sparse, .ready:
                HistoryCard {
                    VStack(spacing: 12) {
                        HistoryGrowthChartView(
                            points: visiblePoints,
                            selectedDate: selectedPoint?.date,
                            metric: selectedMetric,
                            exercise: selectedExercise,
                            range: selectedRange,
                            onSelect: { selectedPointDate = $0 }
                        )
                        if chartAvailability == .sparse {
                            Text("기록이 더 쌓이면 추이 변화를 비교할 수 있어요.")
                                .font(GymupTypography.uiCaption)
                                .foregroundStyle(GymupColors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .accessibilityIdentifier(chartAvailability == .sparse ? "history.growth.sparse" : "history.growth.chart")
            }
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 0) {
            ForEach(ranges, id: \.self) { range in
                let isSelected = selectedRange == range
                Button {
                    selectedRange = range
                } label: {
                    Text(range.rawValue)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(isSelected ? GymupColors.primaryText : GymupColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(isSelected ? GymupColors.elevatedSurface : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("history.growth.range.\(range.id)")
            }
        }
        .padding(4)
        .background(GymupColors.surface, in: Capsule())
        .accessibilityLabel("그래프 조회 기간")
    }

    private var ranges: [HistoryGrowthRange] {
        HistoryGrowthRange.allCases
    }

    private var exercises: [String] {
        HistoryGrowthRecordData.exercises(from: store.records)
    }

    private var allSamples: [HistoryGrowthDataPoint] {
        sampleDataOverride ?? HistoryGrowthRecordData.points(
            from: store.records, exercise: selectedExercise, metric: selectedMetric
        )
    }

    private var visiblePoints: [HistoryGrowthDataPoint] {
        selectedRange.recordedPoints(from: allSamples, now: anchorDate)
    }

    private var selectedPoint: HistoryGrowthDataPoint? {
        guard !visiblePoints.isEmpty else { return nil }
        return visiblePoints.first { $0.date == selectedPointDate } ?? visiblePoints.last
    }

    private var chartAvailability: HistoryGrowthChartAvailability {
        HistoryGrowthChartAvailability(points: visiblePoints)
    }

    private var changeValue: Double? {
        guard let selectedPoint,
              let selectedIndex = allSamples.firstIndex(where: { $0.date == selectedPoint.date }) else { return nil }
        let comparisonIndex = allSamples.firstIndex { $0.date == visiblePoints.first?.date } ?? selectedIndex
        guard comparisonIndex < selectedIndex else { return nil }
        return selectedPoint.value - allSamples[comparisonIndex].value
    }

    private var changeDescription: String {
        guard let value = changeValue else { return "첫 기록이에요" }
        return "기간 내 첫 기록보다 \(value >= 0 ? "+" : "")\(formattedValue(value))\(selectedMetric.unit)"
    }

    private var changeIndicatorSymbol: String {
        guard let value = changeValue else { return "minus" }
        if value > 0 { return "arrow.up.right" }
        if value < 0 { return "arrow.down.right" }
        return "minus"
    }

    private var changeIndicatorColor: Color {
        guard let value = changeValue, value > 0 else { return GymupColors.secondaryText }
        return Color(red: 1, green: 0.43, blue: 0.45)
    }

    private var featuredMetricAccessibilityLabel: String {
        guard let selectedPoint else { return "\(selectedMetric.rawValue), 기록 없음" }
        let date = HistoryDateText.string(selectedPoint.date, format: "M월 d일")
        let value = formattedValue(selectedPoint.value)
        return "\(date), \(selectedMetric.rawValue) \(value) \(selectedMetric.unit), \(changeDescription)"
    }

    private func formattedValue(_ value: Double) -> String {
        if selectedMetric == .volume {
            return Int(value.rounded()).formatted()
        }
        return value.formatted(.number.precision(.fractionLength(0...1)))
    }

}

#Preview("G5 성장 그래프") {
    HistoryGrowthView()
        .preferredColorScheme(.dark)
}

#Preview("G5 기록 없음") {
    HistoryGrowthView(sampleDataOverride: [])
        .preferredColorScheme(.dark)
}

#Preview("G5 기록 부족") {
    HistoryGrowthView(sampleDataOverride: [
        HistoryGrowthDataPoint(date: .now, value: 62.5)
    ])
    .preferredColorScheme(.dark)
}
