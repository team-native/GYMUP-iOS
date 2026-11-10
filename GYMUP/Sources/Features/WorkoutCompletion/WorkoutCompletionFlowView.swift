import SwiftUI

struct WorkoutCompletionFlowView: View {
    let data: WorkoutCompletionData
    let onWorkoutPhoto: () -> Void
    let onFinish: () -> Void
    let onViewItems: () -> Void
    let onCreateGoal: () -> Void
    let onGoalHistory: () -> Void
    let showsPhotoAction: Bool
    let showsPeakGoalActions: Bool
    var rewardErrorMessage: String?
    var isLoadingReward = false
    var onRetryReward: () -> Void = {}

    @State private var step: WorkoutCompletionStep = .summary

    init(
        data: WorkoutCompletionData = .sample,
        onWorkoutPhoto: @escaping () -> Void = {},
        onFinish: @escaping () -> Void = {},
        onViewItems: @escaping () -> Void = {},
        onCreateGoal: @escaping () -> Void = {},
        onGoalHistory: @escaping () -> Void = {},
        showsPhotoAction: Bool = true,
        showsPeakGoalActions: Bool = true,
        rewardErrorMessage: String? = nil,
        isLoadingReward: Bool = false,
        onRetryReward: @escaping () -> Void = {}
    ) {
        self.data = data
        self.onWorkoutPhoto = onWorkoutPhoto
        self.onFinish = onFinish
        self.onViewItems = onViewItems
        self.onCreateGoal = onCreateGoal
        self.onGoalHistory = onGoalHistory
        self.showsPhotoAction = showsPhotoAction
        self.showsPeakGoalActions = showsPeakGoalActions
        self.rewardErrorMessage = rewardErrorMessage
        self.isLoadingReward = isLoadingReward
        self.onRetryReward = onRetryReward
    }

    var body: some View {
        Group {
            switch step {
            case .summary:
                WorkoutSummaryView(
                    data: data,
                    onPhoto: onWorkoutPhoto,
                    showsPhotoAction: showsPhotoAction,
                    rewardErrorMessage: rewardErrorMessage,
                    isLoadingReward: isLoadingReward,
                    onRetryReward: onRetryReward
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
                        onFinish: onFinish,
                        onCreateGoal: onCreateGoal,
                        onGoalHistory: onGoalHistory,
                        showsGoalActions: showsPeakGoalActions
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
