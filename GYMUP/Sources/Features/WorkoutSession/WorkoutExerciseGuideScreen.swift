import AVKit
import SwiftUI

struct WorkoutExerciseGuideScreen: View {
    let exercise: WorkoutSessionExercise
    let guide: ExerciseGuideResponse?
    let guideError: String?
    let isLoadingGuide: Bool
    let onRetryGuide: () -> Void
    let onClose: () -> Void

    init(
        exercise: WorkoutSessionExercise,
        guide: ExerciseGuideResponse? = nil,
        guideError: String? = nil,
        isLoadingGuide: Bool = false,
        onRetryGuide: @escaping () -> Void = {},
        onClose: @escaping () -> Void
    ) {
        self.exercise = exercise
        self.guide = guide
        self.guideError = guideError
        self.isLoadingGuide = isLoadingGuide
        self.onRetryGuide = onRetryGuide
        self.onClose = onClose
    }

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

    }

    private var videoHero: some View {
        ZStack {
            if let mediaURL = validMediaURL {
                WorkoutGuideVideoPlayer(url: mediaURL)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
                    .accessibilityIdentifier("workout.guide.video-player")
            } else {
                Image(exercise.imageAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()

                Text("영상 준비 중")
                    .font(GymupTypography.uiBold)
                    .foregroundStyle(GymupColors.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(GymupColors.canvas.opacity(0.85), in: Capsule())
                    .accessibilityLabel("자세 영상은 준비 중이에요. 아래 자세 설명을 확인해 주세요.")
                    .accessibilityIdentifier("workout.guide.video-unavailable")
            }
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

            if let guideError {
                WorkoutSessionRecordRetryBanner(
                    message: guideError,
                    isLoading: isLoadingGuide,
                    retryAccessibilityLabel: "자세 가이드 다시 시도",
                    retryAccessibilityIdentifier: "workout.guide.retry",
                    onRetry: onRetryGuide
                )
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
            ForEach(Array(displayedMuscles.enumerated()), id: \.offset) { index, muscle in
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
            ForEach(Array(displayedKeyPoints.prefix(3).enumerated()), id: \.offset) { index, step in
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

            ForEach(Array(displayedCommonMistakes.prefix(2).enumerated()), id: \.offset) { _, mistake in
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

    private var validMediaURL: URL? {
        guard let value = guide?.mediaUrl,
              let url = URL(string: value),
              url.scheme?.lowercased() == "https",
              url.host != nil else { return nil }
        return url
    }

    private var displayedMuscles: [String] {
        guide?.targetMuscles.isEmpty == false ? guide?.targetMuscles ?? [] : exercise.guideMuscleGroups
    }

    private var displayedKeyPoints: [String] {
        guide?.keyPoints.isEmpty == false ? guide?.keyPoints ?? [] : exercise.formSteps
    }

    private var displayedCommonMistakes: [String] {
        guide?.commonMistakes.isEmpty == false ? guide?.commonMistakes ?? [] : exercise.commonMistakes
    }
}

private struct WorkoutGuideVideoPlayer: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                GymupColors.canvas
                    .overlay { ProgressView().tint(GymupColors.primaryText) }
            }
        }
        .onAppear {
            guard player == nil else { return }
            player = AVPlayer(url: url)
        }
        .onChange(of: url) { _, newURL in
            player?.pause()
            player = AVPlayer(url: newURL)
        }
        .onDisappear { player?.pause() }
    }
}
