import SwiftUI

struct HistoryGrowthChartView: View {
    let points: [HistoryGrowthDataPoint]
    let selectedDate: Date?
    let metric: HistoryGrowthMetric
    let exercise: String
    let range: HistoryGrowthRange
    let onSelect: (Date) -> Void

    private var selectedIndex: Int? {
        guard let selectedDate else { return points.indices.last }
        return points.firstIndex { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            ?? points.indices.last
    }

    private var selectedPoint: HistoryGrowthDataPoint? {
        guard let selectedIndex, points.indices.contains(selectedIndex) else { return nil }
        return points[selectedIndex]
    }

    private var domain: ClosedRange<Double> {
        guard let minimum = points.map(\.value).min(), let maximum = points.map(\.value).max() else { return 0...1 }
        let span = maximum - minimum
        let padding = span == 0 ? max(abs(maximum) * 0.1, 1) : span * 0.16
        return (minimum - padding)...(maximum + padding)
    }

    private var yAxisValues: [Double] {
        (0...3).map { index in
            domain.upperBound - (domain.upperBound - domain.lowerBound) * Double(index) / 3
        }
    }

    private var axisLabels: [HistoryGrowthAxisLabel] {
        range.axisLabels(for: points)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                yAxis
                    .frame(width: 36, height: 156)
                plot
                    .frame(height: 156)
            }
            xAxis
                .padding(.leading, 44)
            legend
        }
    }

    private var yAxis: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(yAxisValues.enumerated()), id: \.offset) { tick in
                Text(axisValue(tick.element))
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .accessibilityHidden(true)
    }

    private var plot: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let positions = points.indices.map { pointPosition(at: $0, in: size) }
            ZStack(alignment: .topLeading) {
                ForEach(Array(yAxisValues.enumerated()), id: \.offset) { tick in
                    Rectangle()
                        .fill(GymupColors.separator)
                        .frame(height: 1)
                        .position(x: size.width / 2, y: size.height * CGFloat(tick.offset) / 3)
                }
                Path { path in
                    guard let first = positions.first else { return }
                    path.move(to: first)
                    for point in positions.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(GymupColors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                if let selectedIndex, positions.indices.contains(selectedIndex) {
                    let point = positions[selectedIndex]
                    Rectangle()
                        .fill(GymupColors.accent.opacity(0.35))
                        .frame(width: 1, height: size.height)
                        .position(x: point.x, y: size.height / 2)
                    Circle()
                        .fill(GymupColors.accent)
                        .frame(width: 10, height: 10)
                        .position(point)
                    Circle()
                        .stroke(GymupColors.canvas, lineWidth: 2)
                        .frame(width: 14, height: 14)
                        .position(point)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { tap in
                        guard !positions.isEmpty, size.width > 0 else { return }
                        let progress = min(max(tap.location.x / size.width, 0), 1)
                        let index = points.count == 1
                            ? 0
                            : Int((progress * CGFloat(points.count - 1)).rounded())
                        onSelect(points[index].date)
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("\(exercise) \(metric.rawValue) 그래프")
            .accessibilityValue(accessibilityValue)
            .accessibilityHint("좌우로 조절해 기록 지점을 선택합니다")
            .accessibilityAdjustableAction { direction in
                guard let selectedIndex else { return }
                let nextIndex: Int
                switch direction {
                case .increment: nextIndex = min(selectedIndex + 1, points.count - 1)
                case .decrement: nextIndex = max(selectedIndex - 1, 0)
                @unknown default: return
                }
                if points.indices.contains(nextIndex) {
                    onSelect(points[nextIndex].date)
                }
            }
        }
    }

    private var xAxis: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(axisLabels) { label in
                    Text(label.title)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .position(x: 16 + (geometry.size.width - 32) * label.position, y: 8)
                }
            }
        }
        .frame(height: 18)
        .accessibilityHidden(true)
    }

    private var legend: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(GymupColors.accent)
                .frame(width: 18, height: 3)
                .accessibilityHidden(true)
            Text("\(exercise) · \(metric.rawValue) (\(metric.unit))")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var accessibilityValue: String {
        guard let selectedPoint else { return "기록 없음" }
        return "\(HistoryDateText.string(selectedPoint.date, format: "M월 d일")), \(axisValue(selectedPoint.value)) \(metric.unit)"
    }

    private func pointPosition(at index: Int, in size: CGSize) -> CGPoint {
        let point = points[index]
        let xPosition = points.count == 1 ? size.width / 2 : size.width * CGFloat(index) / CGFloat(points.count - 1)
        let fraction = (point.value - domain.lowerBound) / (domain.upperBound - domain.lowerBound)
        let yPosition = size.height * CGFloat(1 - fraction)
        return CGPoint(x: xPosition, y: yPosition)
    }

    private func axisValue(_ value: Double) -> String {
        if metric == .volume {
            return "\((value / 1_000).formatted(.number.precision(.fractionLength(0...1))))K"
        }
        return value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
