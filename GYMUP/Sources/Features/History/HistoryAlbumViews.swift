import SwiftUI

struct HistoryAlbumView: View {
    let store: HistoryStore
    let onOpenRoutines: () -> Void
    let onOpenDetail: (UUID) -> Void
    let onCompare: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: String?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            HistoryNavigationBar(
                title: "Progress Album",
                onBack: dismiss.callAsFunction,
                actionTitle: store.records.isEmpty ? nil : "비교",
                action: compareAction
            )
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if albumData.hasRecords {
                        exerciseFilter
                    }
                    if albumData.months.isEmpty {
                        emptyContent
                    } else {
                        ForEach(albumData.months) { group in
                            monthSection(group)
                        }
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

    private var exerciseFilter: some View {
        Menu {
            Button("전체 운동") { selectedExercise = nil }
            ForEach(albumData.exerciseOptions, id: \.self) { exercise in
                Button(exercise) { selectedExercise = exercise }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 13, weight: .semibold))
                Text(selectedExercise ?? "운동 종목")
                    .font(GymupTypography.uiCaption)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(GymupColors.primaryText)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(GymupColors.surface, in: Capsule())
        }
        .accessibilityLabel("운동 종목 필터")
        .accessibilityValue(selectedExercise ?? "전체 운동")
        .accessibilityIdentifier("history.album.exerciseFilter")
    }

    private func monthSection(_ group: HistoryAlbumSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HistorySectionTitle(title: group.title, subtitle: "\(group.records.count)장")
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(group.records) { record in
                    Button {
                        onOpenDetail(record.id)
                    } label: {
                        HistoryAlbumTile(record: record)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(record.albumAccessibilityLabel)
                    .accessibilityHint("운동 사진과 상세 기록 열기")
                    .accessibilityIdentifier("history.album.\(record.id.uuidString)")
                }
            }
        }
    }

    private var albumData: HistoryAlbumData {
        HistoryAlbumData(records: store.records, selectedExercise: selectedExercise)
    }

    private var compareAction: (() -> Void)? {
        guard let record = store.records.first else { return nil }
        return { onCompare(record.photoAssetName) }
    }

    private var emptyContent: some View {
        let noRecords = !albumData.hasRecords
        return VStack(spacing: 12) {
            Image(systemName: noRecords ? "photo.on.rectangle.angled" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(GymupColors.secondaryText)
                .accessibilityHidden(true)
            Text(noRecords ? "아직 모은 운동 사진이 없어요" : "선택한 운동의 사진이 없어요")
                .font(GymupTypography.uiStrong)
                .foregroundStyle(GymupColors.primaryText)
                .multilineTextAlignment(.center)
            Text(emptyDescription(noRecords: noRecords))
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if noRecords {
                Button(action: onOpenRoutines) {
                    Text("루틴 시작하기")
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background(GymupColors.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("루틴 시작하기")
                .accessibilityIdentifier("history.album.startRoutine")
            } else if selectedExercise != nil {
                Button("전체 운동 보기") { selectedExercise = nil }
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.accent)
                    .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(24)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("history.album.emptyState")
    }

    private func emptyDescription(noRecords: Bool) -> String {
        if noRecords {
            return "운동을 완료하고 사진을 남기면 이곳에서 모아볼 수 있어요."
        }
        return "다른 운동 종목을 선택해 보세요."
    }
}

private struct HistoryAlbumTile: View {
    let record: WorkoutRecord

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                HistoryWorkoutPhoto(assetName: record.photoAssetName)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .accessibilityHidden(true)
                LinearGradient(
                    colors: [.clear, .black.opacity(0.62)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                Text(HistoryDateText.string(record.date, format: "M.d"))
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.46), in: Capsule())
                    .padding(7)
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.76, contentMode: .fit)
    }
}

private extension WorkoutRecord {
    var albumAccessibilityLabel: String {
        let exercises = self.exercises.map(\.name).joined(separator: ", ")
        return "\(HistoryDateText.string(date, format: "M월 d일")), \(routineName), \(exercises) 운동 사진"
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
    HistoryAlbumView(
        store: HistoryStore(records: HistoryListSampleData.records),
        onOpenRoutines: {},
        onOpenDetail: { _ in },
        onCompare: { _ in }
    )
        .preferredColorScheme(.dark)
}
