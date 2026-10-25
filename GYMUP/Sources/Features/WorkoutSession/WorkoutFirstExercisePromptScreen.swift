import SwiftUI

struct WorkoutFirstExercisePromptScreen: View {
    let exercise: WorkoutSessionExercise
    let onViewGuide: () -> Void
    let onStartNow: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                background

                VStack(alignment: .leading, spacing: 15) {
                    Image("H1IconSparkle")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(GymupColors.brandText)
                        .frame(width: 20, height: 20)
                        .frame(width: 43, height: 43)
                        .background(GymupColors.brandSubtle, in: Circle())

                    Text("처음 하는 운동이에요")
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                        .padding(.top, 1)

                    Text("\(exercise.name)은 첫 기록이에요.\n30초 자세 가이드를 먼저 볼까요?")
                        .font(GymupTypography.callout)
                        .lineSpacing(3)
                        .foregroundStyle(GymupColors.secondaryText)

                    VStack(spacing: 10) {
                        Button(action: onViewGuide) {
                            Text("가이드 보기")
                                .font(GymupTypography.uiBold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(GymupColors.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("workout.first-exercise.guide")

                        Button(action: onStartNow) {
                            Text("바로 시작")
                                .font(GymupTypography.uiBold)
                                .foregroundStyle(GymupColors.primaryText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(GymupColors.elevatedSurface, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("workout.first-exercise.start")
                    }
                    .padding(.top, 7)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, max(34, geometry.safeAreaInsets.bottom))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    GymupColors.surface,
                    in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                )
            }
            .ignoresSafeArea()
            .background(GymupColors.canvas)
        }
        .accessibilityIdentifier("workout.first-exercise.prompt")
    }

    private var background: some View {
        GeometryReader { geometry in
            Image(exercise.imageAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.35), location: 0),
                            .init(color: GymupColors.canvas.opacity(0.3), location: 0.48),
                            .init(color: GymupColors.canvas.opacity(0.97), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
        }
    }
}
