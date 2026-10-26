import Foundation

struct HistoryGrowthDataPoint: Identifiable, Equatable {
    let date: Date
    let value: Double

    var id: Date { date }
}

struct HistoryGrowthAxisLabel: Identifiable, Equatable {
    let id: Int
    let title: String
    let position: Double
}

enum HistoryGrowthRange: String, CaseIterable, Identifiable, Hashable {
    case fourWeeks = "4주"
    case twelveWeeks = "12주"
    case sixMonths = "6개월"
    case all = "전체"

    var id: String { rawValue }

    var visiblePointCount: Int? {
        switch self {
        case .fourWeeks: 1
        case .twelveWeeks: 4
        case .sixMonths: 7
        case .all: nil
        }
    }

    var comparisonPointCount: Int {
        switch self {
        case .fourWeeks: 1
        case .twelveWeeks: 3
        case .sixMonths: 6
        case .all: 12
        }
    }

    func points(from samples: [HistoryGrowthDataPoint]) -> [HistoryGrowthDataPoint] {
        guard let visiblePointCount else { return samples }
        return Array(samples.suffix(visiblePointCount))
    }

    func axisLabels(for points: [HistoryGrowthDataPoint], calendar: Calendar = .current) -> [HistoryGrowthAxisLabel] {
        guard !points.isEmpty else { return [] }
        let step = self == .sixMonths ? 2 : self == .all ? 3 : 1
        var indices = Array(stride(from: 0, to: points.count, by: step))
        if let lastIndex = points.indices.last, indices.last != lastIndex {
            indices.append(lastIndex)
        }
        return indices.map { index in
            let title: String
            if self == .fourWeeks {
                title = index == points.indices.last ? "이번 주" : "4주 전"
            } else {
                title = points[index].date.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).month())
            }
            let position = points.count == 1 ? 0.5 : Double(index) / Double(points.count - 1)
            return HistoryGrowthAxisLabel(id: index, title: title, position: position)
        }
    }
}

enum HistoryGrowthChartAvailability: Equatable {
    case empty
    case sparse
    case ready

    init(points: [HistoryGrowthDataPoint]) {
        switch points.count {
        case 0: self = .empty
        case 1: self = .sparse
        default: self = .ready
        }
    }
}

enum HistoryGrowthSampleData {
    static let exercises = ["벤치프레스", "스쿼트", "랫 풀 다운"]

    private static let bounds: [String: [HistoryGrowthMetric: ClosedRange<Double>]] = [
        "벤치프레스": [
            .maxWeight: 35...62.5,
            .estimatedOneRepMax: 40...70,
            .volume: 4_200...8_420
        ],
        "스쿼트": [
            .maxWeight: 50...90,
            .estimatedOneRepMax: 60...108,
            .volume: 5_600...11_260
        ],
        "랫 풀 다운": [
            .maxWeight: 20...50,
            .estimatedOneRepMax: 25...60,
            .volume: 3_500...7_840
        ]
    ]

    static func points(
        for metric: HistoryGrowthMetric,
        exercise: String,
        anchorDate: Date = .now,
        calendar: Calendar = .current
    ) -> [HistoryGrowthDataPoint] {
        guard let valueRange = bounds[exercise]?[metric],
              let minimumSeed = metric.progressionSeedValues.min(),
              let maximumSeed = metric.progressionSeedValues.max(),
              maximumSeed > minimumSeed,
              metric.progressionSeedValues.count > 1 else { return [] }

        let seeds = metric.progressionSeedValues
        let sampleCount = seeds.count
        return (0..<sampleCount).compactMap { index in
            let seedValue = seeds[index]
            let progress = (seedValue - minimumSeed) / (maximumSeed - minimumSeed)
            guard let date = calendar.date(byAdding: .month, value: index - (sampleCount - 1), to: anchorDate) else {
                return nil
            }
            return HistoryGrowthDataPoint(
                date: calendar.startOfDay(for: date),
                value: valueRange.lowerBound + (valueRange.upperBound - valueRange.lowerBound) * progress
            )
        }
    }
}
