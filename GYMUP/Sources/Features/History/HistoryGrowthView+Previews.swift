import SwiftUI

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
