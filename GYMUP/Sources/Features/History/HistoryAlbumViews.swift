import SwiftUI

struct HistoryAlbumView: View {
    let onCompare: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 0) {
            HistoryNavigationBar(
                title: "Progress Album",
                onBack: dismiss.callAsFunction,
                actionTitle: "비교",
                action: { onCompare(HistorySampleData.records[0].photoAssetName) }
            )
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    albumIntro
                    ForEach(monthGroups, id: \.title) { group in
                        monthSection(group)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var albumIntro: some View {
        Text("운동 사진을 모아 변화를 비교해 보세요.")
            .font(GymupTypography.callout)
            .foregroundStyle(GymupColors.secondaryText)
    }

    private func monthSection(_ group: HistoryAlbumMonth) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HistorySectionTitle(title: group.title, subtitle: "\(group.records.count)장")
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(group.records) { record in
                    Button {
                        onCompare(record.photoAssetName)
                    } label: {
                        HistoryAlbumTile(record: record)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("history.album.\(record.id.uuidString)")
                }
            }
        }
    }

    private var monthGroups: [HistoryAlbumMonth] {
        let grouped = Dictionary(grouping: HistorySampleData.records) {
            HistoryDateText.string($0.date, format: "yyyy년 M월")
        }
        return grouped.keys.sorted(by: >).compactMap { title in
            guard let records = grouped[title]?.sorted(by: { $0.date > $1.date }) else { return nil }
            return HistoryAlbumMonth(title: title, records: records)
        }
    }
}

private struct HistoryAlbumMonth: Identifiable {
    var id: String { title }
    let title: String
    let records: [WorkoutRecord]
}

private struct HistoryAlbumTile: View {
    let record: WorkoutRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HistoryWorkoutPhoto(assetName: record.photoAssetName)
                .frame(height: 156)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.55), in: Circle())
                        .padding(8)
                        .accessibilityHidden(true)
                }
                .accessibilityHidden(true)
            Text(HistoryDateText.string(record.date, format: "M월 d일"))
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.primaryText)
            Text(record.routineName)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(HistoryDateText.string(record.date, format: "M월 d일")), \(record.routineName), 비교 보기")
    }
}

struct HistoryComparisonView: View {
    let assetName: String
    @Environment(\.dismiss) private var dismiss
    @State private var comparisonPosition = 0.5

    var body: some View {
        VStack(spacing: 0) {
            HistoryNavigationBar(title: "비교 보기", onBack: dismiss.callAsFunction)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    comparisonHeading
                    photos
                    timeline
                    growthSummary
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var comparisonHeading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("나의 변화")
                .font(GymupTypography.title)
                .foregroundStyle(GymupColors.primaryText)
            Text("사진을 움직여 같은 순간의 변화를 확인해요.")
                .font(GymupTypography.callout)
                .foregroundStyle(GymupColors.secondaryText)
        }
    }

    private var photos: some View {
        HStack(spacing: 8) {
            comparisonPhoto(
                assetName: earlierAssetName,
                badge: "BEFORE",
                date: HistoryDateText.string(earlierDate, format: "M월 d일")
            )
            comparisonPhoto(
                assetName: assetName,
                badge: "AFTER",
                date: HistoryDateText.string(HistorySampleData.records[0].date, format: "M월 d일")
            )
        }
        .frame(height: 316)
    }

    private func comparisonPhoto(assetName: String, badge: String, date: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            HistoryWorkoutPhoto(assetName: assetName)
            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 5) {
                Text(badge)
                    .font(GymupTypography.uiCaption)
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.75))
                Text(date)
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(.white)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(badge == "BEFORE" ? "비교 전" : "비교 후"), \(date) 사진")
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("12주 동안의 변화")
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                Spacer()
                Text("\(Int(comparisonPosition * 100))%")
                    .font(GymupTypography.number)
                    .foregroundStyle(GymupColors.accent)
            }
            Slider(value: $comparisonPosition, in: 0...1)
                .tint(GymupColors.accent)
                .accessibilityLabel("비교 시점")
                .accessibilityValue("\(Int(comparisonPosition * 100))퍼센트")
        }
        .padding(16)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var growthSummary: some View {
        HistoryCard {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(GymupColors.accent)
                    .frame(width: 40, height: 40)
                    .background(GymupColors.accent.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text("운동 기록으로 쌓은 성장")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                    Text("벤치프레스 최고 무게 +12.5kg")
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var earlierAssetName: String {
        assetName == "H1RoutinePhoto" ? "R1RoutineUpper" : "H1RoutinePhoto"
    }

    private var earlierDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: -12, to: HistorySampleData.records[0].date)
            ?? HistorySampleData.records[0].date
    }
}

#Preview {
    HistoryAlbumView(onCompare: { _ in })
        .preferredColorScheme(.dark)
}
