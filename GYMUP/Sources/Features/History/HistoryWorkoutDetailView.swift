import SwiftUI

struct HistoryDetailView: View {
    let record: WorkoutRecord
    let onOpenAlbum: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isShowingAllExercises = false

    var body: some View {
        VStack(spacing: 0) {
            detailNavigationBar
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    metrics
                    photoBanner
                    exerciseList
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var detailNavigationBar: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                backButton
                Text(detailTitle)
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("history.detail.title")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        } else {
            HStack(spacing: 4) {
                backButton
                Spacer(minLength: 0)
                Text(detailTitle)
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .accessibilityIdentifier("history.detail.title")
                Spacer(minLength: 0)
                Color.clear
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 52)
        }
    }

    private var backButton: some View {
        Button(action: dismiss.callAsFunction) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(GymupColors.primaryText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("뒤로")
        .accessibilityIdentifier("history.detail.back")
    }

    private var detailTitle: String {
        "\(HistoryDateText.string(record.date, format: "M월 d일")) · \(record.routineName)"
    }

    private var metrics: some View {
        HistoryCard {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 0) {
                    accessibilityMetricRow(title: "시간", value: "\(record.durationMinutes)", unit: "분")
                    horizontalMetricDivider
                    accessibilityMetricRow(title: "총 세트", value: "\(record.setCount)", unit: "세트")
                    horizontalMetricDivider
                    accessibilityMetricRow(title: "총 볼륨", value: record.volumeKilograms.formatted(), unit: "KG")
                }
            } else {
                HStack(spacing: 10) {
                    HistoryMetricCell(value: "\(record.durationMinutes)", unit: "분", title: "시간")
                    metricDivider
                    HistoryMetricCell(value: "\(record.setCount)", unit: "세트", title: "총 세트")
                    metricDivider
                    HistoryMetricCell(value: record.volumeKilograms.formatted(), unit: "KG", title: "총 볼륨")
                }
            }
        }
    }

    private func accessibilityMetricRow(title: String, value: String, unit: String) -> some View {
        HStack(spacing: 8) {
            Text(title).font(HistoryDetailTypography.caption).foregroundStyle(GymupColors.secondaryText)
            Spacer(minLength: 8)
            Text(value).font(HistoryDetailTypography.metric).foregroundStyle(GymupColors.primaryText).lineLimit(1).minimumScaleFactor(0.7)
            Text(unit).font(HistoryDetailTypography.caption).foregroundStyle(GymupColors.secondaryText)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
    }

    private var horizontalMetricDivider: some View {
        Rectangle().fill(GymupColors.separator).frame(height: 1).accessibilityHidden(true)
    }

    private var metricDivider: some View {
        Rectangle().fill(GymupColors.separator).frame(width: 1, height: 36).accessibilityHidden(true)
    }

    private var photoBanner: some View {
        Button(action: onOpenAlbum) {
            HistoryCard {
                HStack(spacing: 12) {
                    HistoryWorkoutPhoto(assetName: record.photoAssetName)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("오운완 사진 1장")
                            .font(GymupTypography.uiStrong)
                            .foregroundStyle(GymupColors.primaryText)
                        Text("Progress Album에서 보기")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GymupColors.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("오운완 사진 한 장, Progress Album에서 보기")
        .accessibilityIdentifier("history.openAlbum")
    }

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HistorySectionTitle(title: "운동 상세", subtitle: "\(record.exercises.count)종목")
            ForEach(displayedExercises) { HistoryExerciseCard(exercise: $0) }
            if record.exercises.count > 2 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingAllExercises.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(isShowingAllExercises ? "접기" : "운동 종목 더 보기")
                        Image(systemName: isShowingAllExercises ? "chevron.up" : "chevron.down")
                    }
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var displayedExercises: [WorkoutExerciseRecord] {
        isShowingAllExercises ? record.exercises : Array(record.exercises.prefix(2))
    }
}

private struct HistoryExerciseCard: View {
    let exercise: WorkoutExerciseRecord
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HistoryCard {
            VStack(alignment: .leading, spacing: 14) {
                exerciseHeading
                VStack(spacing: 10) {
                    ForEach(exercise.sets) { set in
                        Group {
                            if dynamicTypeSize.isAccessibilitySize {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("\(set.weight.formatted()) kg")
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text("×")
                                        Text("\(set.repetitions)회")
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 8)
                                        Text("\(set.id)세트")
                                            .fixedSize(horizontal: true, vertical: false)
                                    }
                                }
                            } else {
                                HStack {
                                    Text("\(set.id)세트")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    HStack(spacing: 4) {
                                        Text("\(set.weight.formatted()) kg")
                                        Text("×")
                                        Text("\(set.repetitions)회")
                                    }
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                        }
                        .font(HistoryDetailTypography.caption)
                        .foregroundStyle(set.isPersonalRecord ? GymupColors.primaryText : GymupColors.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            set.isPersonalRecord ? GymupColors.accent.opacity(0.16) : GymupColors.elevatedSurface,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay {
                            if set.isPersonalRecord {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(GymupColors.accent.opacity(0.32), lineWidth: 1)
                            }
                        }
                        .accessibilityElement(children: .combine).accessibilityLabel(set.accessibilityDescription)
                    }
                }
            }
        }
        .accessibilityIdentifier("history.detail.exercise.\(exercise.id)")
    }

    @ViewBuilder
    private var exerciseHeading: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(HistoryDetailTypography.body)
                    .foregroundStyle(GymupColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    if hasPersonalRecord { personalRecordBadge }
                    Spacer(minLength: 8)
                    Text("\(exercise.sets.count)세트")
                        .font(HistoryDetailTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                }
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(exercise.name)
                    .font(HistoryDetailTypography.body)
                    .foregroundStyle(GymupColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                if hasPersonalRecord { personalRecordBadge }
                Spacer(minLength: 0)
                Text("\(exercise.sets.count)세트")
                    .font(HistoryDetailTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private var hasPersonalRecord: Bool {
        exercise.sets.contains(where: \.isPersonalRecord)
    }

    private var personalRecordBadge: some View {
        Text("PR").font(HistoryDetailTypography.badge).foregroundStyle(.white)
            .padding(.horizontal, 7).padding(.vertical, 4).background(GymupColors.accent, in: Capsule()).fixedSize()
    }
}

private enum HistoryDetailTypography {
    static let caption = Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption)
    static let body = Font.custom("GothicA1-SemiBold", size: 14, relativeTo: .subheadline)
    static let metric = Font.custom("BarlowCondensed-ExtraBold", size: 18, relativeTo: .title3)
    static let badge = Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption)
}
