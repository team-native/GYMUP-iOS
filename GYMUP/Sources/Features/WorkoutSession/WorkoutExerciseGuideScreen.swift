import SwiftUI

struct WorkoutExerciseGuideScreen: View {
    let exercise: WorkoutSessionExercise
    let onClose: () -> Void

    @State private var isShowingVideoUnavailableAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 19) {
                videoHero
                guideContent
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .background(GymupColors.canvas.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .alert("운동 영상은 준비 중이에요", isPresented: $isShowingVideoUnavailableAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("자세 설명을 확인한 뒤 세트를 진행해 주세요.")
        }
    }

    private var videoHero: some View {
        ZStack {
            Image(exercise.imageAssetName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipped()

            Button {
                isShowingVideoUnavailableAlert = true
            } label: {
                Image("R1IconPlay")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .frame(width: 52, height: 52)
                    .background(GymupColors.accent, in: Circle())
            }
            .buttonStyle(.plain)
            .offset(y: -6)
            .accessibilityLabel("자세 영상 재생")
            .accessibilityIdentifier("workout.guide.play-video")
        }
        .frame(height: 300)
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image("R3IconClose")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .frame(width: 30, height: 30)
                    .background(GymupColors.elevatedSurface, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 58)
            .padding(.trailing, 22)
            .accessibilityLabel("가이드 닫기")
            .accessibilityIdentifier("workout.guide.close")
        }
    }

    private var guideContent: some View {
        VStack(alignment: .leading, spacing: 19) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.guideDisplayTitle)
                    .font(GymupTypography.display)
                    .foregroundStyle(GymupColors.primaryText)
                Text(exercise.name)
                    .font(GymupTypography.uiMedium)
                    .foregroundStyle(GymupColors.secondaryText)
            }

            muscleChips
            keySteps
            commonMistakes
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    private var muscleChips: some View {
        HStack(spacing: 8) {
            ForEach(Array(exercise.guideMuscleGroups.enumerated()), id: \.offset) { index, muscle in
                Text(muscle)
                    .font(GymupTypography.uiMedium)
                    .foregroundStyle(index == 0 ? .white : GymupColors.primaryText)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background {
                        Capsule()
                            .fill(index == 0 ? GymupColors.accent : .clear)
                            .overlay {
                                Capsule().strokeBorder(
                                    index == 0 ? .clear : GymupColors.strongBorder,
                                    lineWidth: 1
                                )
                            }
                    }
            }
        }
    }

    private var keySteps: some View {
        VStack(spacing: 0) {
            ForEach(Array(exercise.formSteps.prefix(3).enumerated()), id: \.offset) { index, step in
                HStack(alignment: .center, spacing: 14) {
                    Text(String(format: "%02d", index + 1))
                        .font(.custom("BarlowCondensed-ExtraBold", size: 18))
                        .foregroundStyle(GymupColors.brandText)
                    Text(step)
                        .font(GymupTypography.callout)
                        .tracking(-0.18)
                        .foregroundStyle(GymupColors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(GymupColors.border).frame(height: 1)
                }
            }
        }
    }

    private var commonMistakes: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("흔한 실수")
                .font(GymupTypography.label)
                .tracking(0.16)
                .foregroundStyle(GymupColors.critical)

            ForEach(Array(exercise.commonMistakes.prefix(2).enumerated()), id: \.offset) { _, mistake in
                HStack(spacing: 10) {
                    Image("R3IconClose")
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(mistake)
                        .font(GymupTypography.uiMedium)
                        .foregroundStyle(GymupColors.primaryText)
                }
            }
        }
    }

    private var footer: some View {
        Button(action: onClose) {
            Text("확인하고 시작")
                .font(GymupTypography.uiBold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(GymupColors.accent, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 36)
        .accessibilityIdentifier("workout.guide.confirm")
        .background(GymupColors.canvas)
    }
}
