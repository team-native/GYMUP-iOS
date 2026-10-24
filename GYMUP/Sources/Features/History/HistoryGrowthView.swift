import SwiftUI

struct HistoryGrowthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMetric: HistoryGrowthMetric = .maxWeight
    @State private var selectedExercise = "벤치프레스"
    @State private var selectedRange = "12주"
    private let ranges = ["4주", "12주", "6개월", "전체"]
    private let exercises = ["벤치프레스", "스쿼트", "랫 풀 다운"]

    var body: some View {
        VStack(spacing: 0) {
            HistoryNavigationBar(title: "성장 그래프", onBack: dismiss.callAsFunction)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    exercisePicker
                    metricPicker
                    featuredMetric
                    chart
                    rangePicker
                    insight
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var exercisePicker: some View {
        Menu {
            ForEach(exercises, id: \.self) { exercise in
                Button(exercise) { selectedExercise = exercise }
            }
        } label: {
            HStack(spacing: 8) {
                Text(selectedExercise)
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
        .accessibilityLabel("운동 종목, 벤치프레스")
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
                        .frame(minHeight: 40)
                        .background(isSelected ? GymupColors.accent : GymupColors.surface, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private var featuredMetric: some View {
        HistoryCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedMetric.rawValue)
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(metricValue)
                        .font(GymupTypography.growthScore)
                        .foregroundStyle(GymupColors.primaryText)
                    Text(selectedMetric.unit)
                        .font(GymupTypography.growthScoreUnit)
                        .foregroundStyle(GymupColors.secondaryText)
                }
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("이전 기록보다 \(metricChange)")
                        .font(GymupTypography.uiCaption)
                }
                .foregroundStyle(Color(red: 1, green: 0.43, blue: 0.45))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(metricAccessibilityDescription)
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HistorySectionTitle(title: "기록 변화", subtitle: selectedExercise)
            HistoryCard {
                VStack(spacing: 12) {
                    HistoryGrowthChart(values: displayedChartValues)
                        .frame(height: 156)
                    HStack {
                        ForEach(chartLabels, id: \.self) { month in
                            Text(month)
                                .font(GymupTypography.uiCaption)
                                .foregroundStyle(GymupColors.secondaryText)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
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
                    Text(range)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(isSelected ? GymupColors.primaryText : GymupColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(isSelected ? GymupColors.elevatedSurface : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(GymupColors.surface, in: Capsule())
        .accessibilityLabel("그래프 조회 기간")
    }

    private var insight: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(GymupColors.accent)
                .accessibilityHidden(true)
            Text("꾸준히 쌓은 기록 덕분에 지난 기간보다 더 무거운 무게를 들고 있어요.")
                .font(GymupTypography.callout)
                .foregroundStyle(GymupColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var metricValue: String {
        switch selectedExercise {
        case "스쿼트":
            switch selectedMetric {
            case .maxWeight: "90"
            case .estimatedOneRepMax: "108"
            case .volume: "11,260"
            }
        case "랫 풀 다운":
            switch selectedMetric {
            case .maxWeight: "50"
            case .estimatedOneRepMax: "60"
            case .volume: "7,840"
            }
        default:
            selectedMetric.value
        }
    }

    private var metricAccessibilityDescription: String {
        "\(selectedMetric.rawValue) \(metricValue) \(selectedMetric.unit), 이전 기록보다 \(metricChange) 증가"
    }

    private var metricChange: String {
        if selectedMetric == .volume {
            return selectedExercise == "스쿼트" ? "+1,860kg" : selectedExercise == "랫 풀 다운" ? "+920kg" : selectedMetric.change
        }
        return selectedExercise == "스쿼트" ? "+15kg" : selectedExercise == "랫 풀 다운" ? "+7.5kg" : selectedMetric.change
    }

    private var displayedChartValues: [CGFloat] {
        let count = selectedRange == "4주" ? 5 : selectedRange == "12주" ? 8 : 11
        return Array(selectedMetric.chartValues.suffix(count))
    }

    private var chartLabels: [String] {
        switch selectedRange {
        case "4주": ["4주 전", "3주 전", "2주 전", "지난주", "이번 주"]
        case "12주": ["8월", "9월", "10월"]
        case "6개월": ["5월", "7월", "9월", "10월"]
        default: ["7월", "8월", "9월", "10월"]
        }
    }
}

private struct HistoryGrowthChart: View {
    let values: [CGFloat]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let points = chartPoints(in: size)
            ZStack {
                VStack {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle()
                            .fill(GymupColors.separator)
                            .frame(height: 1)
                        Spacer(minLength: 0)
                    }
                }
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(GymupColors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                if let last = points.last {
                    Circle()
                        .fill(GymupColors.accent)
                        .frame(width: 10, height: 10)
                        .position(last)
                }
            }
            .accessibilityHidden(true)
        }
        .accessibilityElement()
        .accessibilityLabel("7월부터 10월까지 상승하는 운동 기록 그래프")
    }

    private func chartPoints(in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        return values.enumerated().map { index, value in
            CGPoint(
                x: size.width * CGFloat(index) / CGFloat(values.count - 1),
                y: size.height * (1 - value) * 0.86 + size.height * 0.07
            )
        }
    }
}

#Preview {
    HistoryGrowthView()
        .preferredColorScheme(.dark)
}
