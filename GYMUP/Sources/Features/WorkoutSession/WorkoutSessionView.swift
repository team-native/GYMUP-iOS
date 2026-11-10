import Combine
import SwiftUI
import UIKit

struct WorkoutSessionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @State var viewModel: WorkoutSessionViewModel
    @State var settings = WorkoutSettings.shared
    @State var didSaveHistoryRecord = false
    let historyStore: HistoryStore
    @State var isConfirmingFinish = false
    @State var isShowingWorkoutPhoto = false
    @State var photoCompletionData: WorkoutCompletionData?
    @State var isShowingPlaylist = false
    @State var isShowingRestFinishedAlert = false
    @State var guideIndex = 0
    @State var isShowingCurrentGuide = false
    @State var isShowingFirstExercisePrompt = false
    @State var promptedExerciseIDs: Set<String> = []
    @State var isShowingWorkoutProcessing = false
    @State var isShowingServerActionError = false
    @State var isShowingWeightInput = false
    @State var weightInputSetIndex: Int?
    @State var liveActivitySessionID = UUID().uuidString

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @MainActor
    init(routineID: String, historyStore: HistoryStore) {
        let exerciseReadService = Self.makePreviousRecordService()
        _viewModel = State(
            initialValue: WorkoutSessionViewModel(
                routineID: routineID,
                historyStore: historyStore,
                previousRecordService: exerciseReadService,
                exerciseGuidanceService: exerciseReadService
            )
        )
        self.historyStore = historyStore
    }

    @MainActor
    init(
        plan: WorkoutSessionPlan,
        historyStore: HistoryStore,
        serverWorkoutID: String? = nil,
        startedAt: Date = .now,
        serverWorkoutVersion: Int? = nil
    ) {
        let exerciseReadService = Self.makePreviousRecordService()
        _viewModel = State(
            initialValue: WorkoutSessionViewModel(
                plan: plan,
                startedAt: startedAt,
                historyStore: historyStore,
                previousRecordService: exerciseReadService,
                exerciseGuidanceService: exerciseReadService,
                serverWorkoutID: serverWorkoutID,
                serverWorkoutVersion: serverWorkoutVersion,
                progressService: serverWorkoutID == nil ? nil : Self.makeProgressService(),
                nextSetService: serverWorkoutID == nil ? nil : Self.makeWorkoutReadService(),
                completionService: serverWorkoutID == nil ? nil : Self.makeCompletionService(),
                rewardService: serverWorkoutID == nil ? nil : Self.makeWorkoutRewardService()
            )
        )
        self.historyStore = historyStore
    }

    var body: some View {
        workoutStateChanges
    }

    private var workoutStateChanges: some View {
        workoutRestAlerts
            .onChange(of: viewModel.currentExerciseIndex) { _, _ in
                isShowingCurrentGuide = false
            }
            .onChange(of: isShowingCurrentGuide) { _, isShowing in
                guard isShowing, let exerciseID = viewModel.currentExercise?.id else { return }
                Task { await viewModel.exerciseGuidance.loadExerciseGuide(for: exerciseID, in: viewModel.plan) }
            }
            .onChange(of: viewModel.finishedAt) { _, finishedAt in
                guard finishedAt != nil else { return }
                settings.cancelRestNotification(sessionID: liveActivitySessionID)
                Task { await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID) }
            }
            .task(id: "\(viewModel.hasStarted)-\(viewModel.currentExercise?.id ?? "")") {
                guard viewModel.hasStarted, let exerciseID = viewModel.currentExercise?.id else { return }
                await loadPreviousRecord(for: exerciseID)
            }
    }

    private var workoutRestAlerts: some View {
        workoutPresentation
            .onReceive(clock) { date in
                Task { @MainActor in await handleRestTick(at: date) }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                refreshRestOnForeground()
            }
            .alert(
                isShowingServerActionError ? "서버 요청을 처리하지 못했어요" : "휴식 시간이 끝났어요",
                isPresented: restAlertPresentation
            ) {
                restAlertActions
            } message: {
                restAlertMessage
            }
    }

    private var workoutPresentation: some View {
        workoutBaseContent
            .sheet(
                isPresented: $isShowingWorkoutPhoto,
                onDismiss: { photoCompletionData = nil },
                content: { workoutPhotoSheetContent }
            )
            .sheet(isPresented: $isShowingPlaylist, content: { playlistSheetContent })
            .sheet(
                isPresented: $isShowingWeightInput,
                onDismiss: { weightInputSetIndex = nil },
                content: { weightInputSheetContent }
            )
            .fullScreenCover(isPresented: $isShowingCurrentGuide, content: { currentGuideCoverContent })
            .fullScreenCover(isPresented: $isShowingFirstExercisePrompt, content: { firstExercisePromptContent })
    }

    private var workoutBaseContent: some View {
        workoutRootContent
            .background(GymupColors.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .overlay { finishConfirmationOverlay }
    }

    private var workoutRootContent: some View {
        Group {
            if isShowingWorkoutProcessing {
                WorkoutSessionProcessingScreen()
            } else if let data = viewModel.completionData {
                WorkoutCompletionFlowView(
                    data: data,
                    onWorkoutPhoto: {
                        photoCompletionData = data
                        isShowingWorkoutPhoto = true
                    },
                    onFinish: finishWorkout,
                    showsPhotoAction: data.progressShotAvailable ?? true,
                    showsPeakGoalActions: false,
                    rewardErrorMessage: viewModel.rewardErrorMessage,
                    isLoadingReward: viewModel.isLoadingReward,
                    onRetryReward: { Task { await viewModel.loadWorkoutReward() } }
                )
            } else if !viewModel.hasStarted {
                preparationContent
            } else {
                sessionContent
            }
        }
    }

    @ViewBuilder
    private var finishConfirmationOverlay: some View {
        if isConfirmingFinish {
            WorkoutExitConfirmationDialog(
                completedExerciseCount: viewModel.completedExerciseCount,
                completedSetCount: viewModel.plan.exercises.reduce(0) { $0 + $1.completedSetCount },
                onFinish: finishWorkoutSession,
                onContinue: { isConfirmingFinish = false }
            )
            .transition(.opacity)
            .zIndex(2)
        }
    }

    @ViewBuilder
    private var workoutPhotoSheetContent: some View {
        if let photoCompletionData {
            WorkoutPhotoFlowView(
                data: photoCompletionData,
                onClose: { isShowingWorkoutPhoto = false },
                workoutId: viewModel.serverWorkoutID
            )
            .presentationDragIndicator(.visible)
        }
    }

    private var playlistSheetContent: some View {
        ProfilePlaylistSheetView()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var weightInputSheetContent: some View {
        if let setIndex = weightInputSetIndex,
           let exercise = viewModel.currentExercise,
           exercise.sets.indices.contains(setIndex) {
            WorkoutSessionWeightInputSheet(
                setNumber: setIndex + 1,
                initialWeight: exercise.sets[setIndex].weightKilograms,
                onConfirm: { weight in
                    viewModel.updateWeight(
                        weight,
                        exerciseIndex: viewModel.currentExerciseIndex,
                        setIndex: setIndex
                    )
                    isShowingWeightInput = false
                }
            )
            .presentationDetents([.height(506)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
            .presentationBackground(GymupColors.surface)
        }
    }

    @ViewBuilder
    private var currentGuideCoverContent: some View {
        if let exercise = viewModel.currentExercise {
            WorkoutExerciseGuideScreen(
                exercise: exercise,
                guide: viewModel.exerciseGuidance.exerciseGuide(for: exercise.id),
                guideError: viewModel.exerciseGuidance.exerciseGuideError(for: exercise.id),
                isLoadingGuide: viewModel.exerciseGuidance.isLoadingExerciseGuide(for: exercise.id),
                onRetryGuide: {
                    Task {
                        await viewModel.exerciseGuidance.loadExerciseGuide(for: exercise.id, in: viewModel.plan)
                    }
                },
                onClose: { isShowingCurrentGuide = false }
            )
        }
    }

    @ViewBuilder
    private var firstExercisePromptContent: some View {
        if let exercise = viewModel.currentExercise {
            WorkoutFirstExercisePromptScreen(
                exercise: exercise,
                onViewGuide: {
                    isShowingFirstExercisePrompt = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        isShowingCurrentGuide = true
                    }
                },
                onStartNow: { isShowingFirstExercisePrompt = false }
            )
        }
    }

    private var restAlertPresentation: Binding<Bool> {
        Binding(
            get: { isShowingRestFinishedAlert || isShowingServerActionError },
            set: { isPresented in
                if !isPresented {
                    isShowingRestFinishedAlert = false
                    isShowingServerActionError = false
                }
            }
        )
    }

    @ViewBuilder
    private var restAlertActions: some View {
        if isShowingServerActionError {
            Button("재시도") { retryFailedServerAction() }
            if viewModel.failedServerAction == .startRest {
                Button("휴식 건너뛰기", role: .cancel) { skipPendingRestStart() }
            } else {
                Button("취소", role: .cancel) { viewModel.dismissServerActionError() }
            }
        } else {
            Button("다음 세트 진행", role: .cancel) {}
        }
    }

    private var restAlertMessage: some View {
        Group {
            if isShowingServerActionError {
                Text(viewModel.serverActionErrorMessage ?? "다시 시도해 주세요.")
            } else {
                Text("준비가 되면 다음 세트를 시작해 주세요.")
            }
        }
    }

}

#Preview {
    NavigationStack {
        WorkoutSessionView(routineID: "upper-a", historyStore: HistoryStore())
    }
    .preferredColorScheme(.dark)
}
