import Combine
import SwiftUI
import UIKit

struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WorkoutSessionViewModel
    @State private var isConfirmingFinish = false
    @State private var isShowingWorkoutPhoto = false
    @State private var photoCompletionData: WorkoutCompletionData?
    @State private var isShowingPlaylist = false
    @State private var isShowingRestFinishedAlert = false
    @State private var guideIndex = 0
    @State private var isShowingCurrentGuide = false

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(routineID: String) {
        _viewModel = State(initialValue: WorkoutSessionViewModel(routineID: routineID))
    }

    var body: some View {
        Group {
            if let data = viewModel.completionData {
                WorkoutCompletionFlowView(
                    data: data,
                    onWorkoutPhoto: {
                        photoCompletionData = data
                        isShowingWorkoutPhoto = true
                    },
                    onFinish: dismiss.callAsFunction,
                    showsPhotoAction: true,
                    showsPeakGoalActions: false
                )
            } else if !viewModel.hasStarted {
                preparationContent
            } else {
                sessionContent
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(
            isPresented: $isShowingWorkoutPhoto,
            onDismiss: { photoCompletionData = nil },
            content: {
                if let photoCompletionData {
                    WorkoutPhotoFlowView(
                        data: photoCompletionData,
                        onClose: { isShowingWorkoutPhoto = false }
                    )
                    .presentationDragIndicator(.visible)
                }
            }
        )
        .sheet(isPresented: $isShowingPlaylist) {
            ProfilePlaylistSheetView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onReceive(clock) { date in
            guard viewModel.refreshClock(at: date) else { return }
            isShowingRestFinishedAlert = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        .confirmationDialog(
            "운동을 마칠까요?",
            isPresented: $isConfirmingFinish,
            titleVisibility: .visible
        ) {
            Button("계속 운동하기", role: .cancel) {}
            Button("완료 화면 보기") { viewModel.finish() }
        } message: {
            Text("현재까지 기록한 세트 결과로 운동을 마무리합니다.")
        }
        .alert("휴식 시간이 끝났어요", isPresented: $isShowingRestFinishedAlert) {
            Button("다음 세트 진행", role: .cancel) {}
        } message: {
            Text("준비가 되면 다음 세트를 시작해 주세요.")
        }
        .onChange(of: viewModel.currentExerciseIndex) { _, _ in
            isShowingCurrentGuide = false
        }
    }

    private var preparationContent: some View {
        WorkoutSessionPreparationView(
            plan: viewModel.plan,
            selectedExerciseIndex: $guideIndex,
            onBack: dismiss.callAsFunction,
            onStart: { viewModel.start(at: Date()) }
        )
    }

    private var sessionContent: some View {
        Group {
            if let exercise = viewModel.currentExercise,
               exercise.isComplete,
               viewModel.plan.exercises.indices.contains(viewModel.currentExerciseIndex + 1) {
                WorkoutExerciseCompleteScreen(
                    exercise: exercise,
                    nextExercise: viewModel.plan.exercises[viewModel.currentExerciseIndex + 1],
                    nextExerciseIndex: viewModel.currentExerciseIndex + 1,
                    totalExerciseCount: viewModel.plan.exercises.count,
                    onContinue: { _ = viewModel.moveToNextExercise() },
                    onFinish: { isConfirmingFinish = true }
                )
            } else if viewModel.isResting,
               let exercise = viewModel.currentExercise,
               let nextSetIndex = viewModel.currentSetIndex {
                WorkoutSessionRestTimerScreen(
                    exercise: exercise,
                    completedSetCount: exercise.completedSetCount,
                    nextSetIndex: nextSetIndex,
                    remainingSeconds: viewModel.restSecondsRemaining,
                    totalSeconds: viewModel.activeRestDurationSeconds,
                    onExtend: { viewModel.extendRest(by: 15) },
                    onSkip: viewModel.skipRest
                )
            } else if let exercise = viewModel.currentExercise {
                WorkoutTrainModeScreen(
                    routineTitle: viewModel.plan.title,
                    elapsedTime: formattedDuration(viewModel.elapsedSeconds),
                    exercise: exercise,
                    exerciseIndex: viewModel.currentExerciseIndex,
                    totalExerciseCount: viewModel.plan.exercises.count,
                    currentSetIndex: viewModel.currentSetIndex,
                    isShowingGuide: isShowingCurrentGuide,
                    isResting: viewModel.isResting || viewModel.isPaused,
                    isPaused: viewModel.isPaused,
                    restSecondsRemaining: viewModel.restSecondsRemaining,
                    onQuit: { isConfirmingFinish = true },
                    onMusic: { isShowingPlaylist = true },
                    onToggleGuide: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingCurrentGuide.toggle()
                        }
                    },
                    onToggleSet: { setIndex in
                        viewModel.toggleSetCompletion(
                            exerciseIndex: viewModel.currentExerciseIndex,
                            setIndex: setIndex,
                            at: Date()
                        )
                    },
                    onAdjustWeight: viewModel.adjustCurrentWeight,
                    onAdjustRepetitions: viewModel.adjustCurrentRepetitions,
                    onSetDone: { completeCurrentSet(at: Date()) },
                    onSkipRest: viewModel.skipRest,
                    onNextExercise: { _ = viewModel.moveToNextExercise() },
                    onFinish: { isConfirmingFinish = true }
                )
            } else {
                GymupEmptyState(symbol: "dumbbell", title: "운동을 찾을 수 없어요", message: "루틴으로 돌아가 운동을 확인해 주세요.")
            }
        }
    }

    private func completeCurrentSet(at date: Date) {
        guard let currentSetIndex = viewModel.currentSetIndex else { return }
        viewModel.toggleSetCompletion(
            exerciseIndex: viewModel.currentExerciseIndex,
            setIndex: currentSetIndex,
            at: date
        )
    }

    private func formattedDuration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

}

#Preview {
    NavigationStack {
        WorkoutSessionView(routineID: "upper-a")
    }
    .preferredColorScheme(.dark)
}
