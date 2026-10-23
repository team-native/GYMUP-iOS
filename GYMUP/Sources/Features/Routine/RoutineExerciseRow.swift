import SwiftUI

struct RoutineExerciseRow: View {
    let exercise: RoutineExercise

    var body: some View {
        HStack(spacing: 14) {
            Image(exercise.imageAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(minHeight: 21)
                Text(exercise.summary)
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(minHeight: 15)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(GymupColors.border).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
