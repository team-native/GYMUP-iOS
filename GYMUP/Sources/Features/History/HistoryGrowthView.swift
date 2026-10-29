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
            navigationBar
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 19) {
                    scopeTag
                    metricPicker
                    if chartAvailability != .empty { featuredMetric }
                    chart
                    rangePicker
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { if selectedExercise.isEmpty { selectedExercise = exercises.first ?? "" } }
    }

    private var navigationBar: some View {
        HStack(spacing: 8) {
            Button(action: dismiss.callAsFunction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(width: 40, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")

            Spacer(minLength: 0)
            Menu {
                ForEach(exercises, id: \.self) { exercise in
                    Button(exercise) { selectedExercise = exercise }
                }
            } label: {
                Text(selectedExercise.isEmpty ? "성장 그래프" : selectedExercise)
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                    .lineLimit(1)
            }
            .accessibilityIdentifier("history.growth.exercise")
            Spacer(minLength: 0)

            Color.clear.frame(width: 40, height: 48)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 8)
        .frame(height: 48)
        .accessibilityElement(children: .contain)
    }

    private var scopeTag: some View {
        Text("V2 · MVP 제외")
            .font(GymupTypography.uiCaption)
            .foregroundStyle(GymupColors.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(GymupColors.elevatedSurface, in: Capsule())
            .accessibilityIdentifier("history.growth.scope")
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
                        .foregroundStyle(isSelected ? GymupColors.primaryText : GymupColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 28)
                        .background(isSelected ? GymupColors.overlay : .clear, in: RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("history.growth.metric.\(metric.id)")
                .accessibilityLabel(metric.rawValue)
            }
        }
        .padding(2)
        .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 9))
        .accessibilityLabel("성장 지표 선택")
    }

    private var featuredMetric: some View {
        Group {
            if let selectedPoint {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(formattedValue(selectedPoint.value))
                            .font(GymupTypography.growthScore)
                            .foregroundStyle(GymupColors.primaryText)
                        Text(selectedMetric.unit)
                            .font(GymupTypography.growthScoreUnit)
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    Text(changeDescription)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(changeIndicatorColor)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(featuredMetricAccessibilityLabel)
            }
        }
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                VStack(spacing: 8) {
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
                        .frame(minHeight: 28)
                        .background(isSelected ? GymupColors.overlay : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("history.growth.range.\(range.id)")
            }
        }
        .padding(2)
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
        let rangeLabel = selectedRange.comparisonLabel(firstRecordDate: visiblePoints.first?.date, now: anchorDate)
        return "\(rangeLabel)보다 \(value >= 0 ? "+" : "")\(formattedValue(value))\(selectedMetric.unit)"
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
