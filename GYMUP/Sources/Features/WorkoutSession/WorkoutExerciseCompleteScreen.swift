import SwiftUI

struct WorkoutExerciseCompleteScreen: View {
    let exercise: WorkoutSessionExercise
    let nextExercise: WorkoutSessionExercise
    let nextExerciseIndex: Int
    let totalExerciseCount: Int
    let onContinue: () -> Void
    let onFinish: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("EXERCISE COMPLETE")
                        .font(GymupTypography.label)
                        .tracking(0.16)
                        .foregroundStyle(GymupColors.brandText)

                    Text("\(exercise.name.replacingOccurrences(of: " ", with: "")) 완료")
                        .font(.custom("GothicA1-ExtraBold", size: 20))
                        .tracking(-0.43)
                        .foregroundStyle(GymupColors.primaryText)

                    completionMetrics

                    Text("NEXT · \(min(nextExerciseIndex + 2, totalExerciseCount)) / \(totalExerciseCount)")
                        .font(GymupTypography.label)
                        .tracking(0.16)
                        .foregroundStyle(GymupColors.secondaryText)

                    nextExerciseCard
                }
                .padding(.horizontal, 20)
                .padding(.top, max(0, 150 - geometry.frame(in: .global).minY))
                .padding(.bottom, 24)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
    }

    private var completionMetrics: some View {
        HStack(alignment: .top, spacing: 20) {
            metric(value: String(exercise.completedSetCount), label: "세트")
            metric(value: exercise.completedVolumeKilograms.formatted(.number.grouping(.automatic)), label: "KG")
            if let record = exercise.personalRecordSet {
                metric(
                    value: "PR",
                    label: "\(record.weightKilograms.formatted(.number.precision(.fractionLength(0...1)))) × \(record.repetitions)"
                )
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(GymupTypography.display)
                .foregroundStyle(GymupColors.primaryText)
            Text(label)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
        }
    }

    private var nextExerciseCard: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                Image(nextExercise.imageAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: 200)
                    .clipped()

                LinearGradient(
                    colors: [.clear, GymupColors.canvas.opacity(0.9)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(nextExercise.completionCardTitle)
                        .font(GymupTypography.display)
                        .foregroundStyle(GymupColors.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(nextExerciseSummary)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 36)
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("workout.next-exercise.preview")
    }

    private var nextExerciseSummary: String {
        guard let set = nextExercise.sets.first else { return nextExercise.target }
        let weight = set.weightKilograms.formatted(.number.precision(.fractionLength(0...1)))
        return "\(nextExercise.name) · \(nextExercise.sets.count)세트 · \(set.repetitions)회 · \(weight)kg"
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button(action: onContinue) {
                Text("다음 운동")
                    .font(GymupTypography.uiBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(GymupColors.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("workout.complete.next-exercise")

            Button(action: onFinish) {
                Text("운동 종료")
                    .font(GymupTypography.uiBold)
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("workout.complete.finish")
        }
        .padding(.horizontal, 36)
        .padding(.top, 0)
        .background(GymupColors.canvas)
    }
}

private extension WorkoutSessionExercise {
    var completionCardTitle: String {
        id == "incline-press" ? "INCLINE DB PRESS" : displayTitle
    }
}
