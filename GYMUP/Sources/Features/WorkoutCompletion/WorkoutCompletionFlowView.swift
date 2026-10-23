import SwiftUI

struct WorkoutCompletionFlowView: View {
    let data: WorkoutCompletionData
    let onWorkoutPhoto: () -> Void
    let onFinish: () -> Void
    let onViewItems: () -> Void
    let onCreateGoal: () -> Void
    let onGoalHistory: () -> Void
    let showsPhotoAction: Bool

    @State private var step: WorkoutCompletionStep = .summary

    init(
        data: WorkoutCompletionData = .sample,
        onWorkoutPhoto: @escaping () -> Void = {},
        onFinish: @escaping () -> Void = {},
        onViewItems: @escaping () -> Void = {},
        onCreateGoal: @escaping () -> Void = {},
        onGoalHistory: @escaping () -> Void = {},
        showsPhotoAction: Bool = true
    ) {
        self.data = data
        self.onWorkoutPhoto = onWorkoutPhoto
        self.onFinish = onFinish
        self.onViewItems = onViewItems
        self.onCreateGoal = onCreateGoal
        self.onGoalHistory = onGoalHistory
        self.showsPhotoAction = showsPhotoAction
    }

    var body: some View {
        Group {
            switch step {
            case .summary:
                WorkoutSummaryView(
                    data: data,
                    onPhoto: onWorkoutPhoto,
                    showsPhotoAction: showsPhotoAction
                ) {
                    advance(from: .summary)
                }
            case .levelUp:
                if let reward = data.levelReward {
                    WorkoutLevelUpView(reward: reward, onViewItems: onViewItems) {
                        advance(from: .levelUp)
                    }
                }
            case .stageUp:
                if let reward = data.stageReward {
                    WorkoutStageUpView(reward: reward) {
                        advance(from: .stageUp)
                    }
                }
            case .peakUnlock:
                if let reward = data.peakReward {
                    WorkoutPeakUnlockView(
                        reward: reward,
                        onCreateGoal: onCreateGoal,
                        onGoalHistory: onGoalHistory
                    )
                }
            }
        }
        .tint(WorkoutCompletionColors.red)
        .preferredColorScheme(.dark)
    }

    private func advance(from currentStep: WorkoutCompletionStep) {
        guard let nextStep = data.nextStep(after: currentStep) else {
            onFinish()
            return
        }

        withAnimation(.easeInOut(duration: 0.24)) {
            step = nextStep
        }
    }
}
