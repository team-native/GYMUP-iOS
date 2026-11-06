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
        _viewModel = State(
            initialValue: WorkoutSessionViewModel(
                routineID: routineID,
                historyStore: historyStore,
                previousRecordService: Self.makePreviousRecordService()
            )
        )
        self.historyStore = historyStore
    }

    @MainActor
    init(
        plan: WorkoutSessionPlan,
        historyStore: HistoryStore,
        serverWorkoutID: String? = nil,
        startedAt: Date = .now
    ) {
        _viewModel = State(
            initialValue: WorkoutSessionViewModel(
                plan: plan,
                startedAt: startedAt,
                historyStore: historyStore,
                previousRecordService: Self.makePreviousRecordService(),
                serverWorkoutID: serverWorkoutID,
                progressService: serverWorkoutID == nil ? nil : Self.makeProgressService(),
                nextSetService: serverWorkoutID == nil ? nil : Self.makeWorkoutReadService()
            )
        )
        self.historyStore = historyStore
    }

    var body: some View {
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
        .overlay {
            if isConfirmingFinish {
                WorkoutExitConfirmationDialog(
                    completedExerciseCount: viewModel.completedExerciseCount,
                    completedSetCount: viewModel.plan.exercises.reduce(0) { $0 + $1.completedSetCount },
                    onFinish: { viewModel.finish() },
                    onContinue: { isConfirmingFinish = false }
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
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
        .sheet(
            isPresented: $isShowingWeightInput,
            onDismiss: { weightInputSetIndex = nil },
            content: {
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
        )
        .fullScreenCover(isPresented: $isShowingCurrentGuide) {
            if let exercise = viewModel.currentExercise {
                WorkoutExerciseGuideScreen(
                    exercise: exercise,
                    onClose: { isShowingCurrentGuide = false }
                )
            }
        }
        .fullScreenCover(isPresented: $isShowingFirstExercisePrompt) {
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
        .onReceive(clock) { date in
            Task { @MainActor in await handleRestTick(at: date) }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refreshRestOnForeground()
        }
        .alert(
            isShowingServerActionError ? "서버 요청을 처리하지 못했어요" : "휴식 시간이 끝났어요",
            isPresented: Binding(
                get: { isShowingRestFinishedAlert || isShowingServerActionError },
                set: { isPresented in
                    if !isPresented {
                        isShowingRestFinishedAlert = false
                        isShowingServerActionError = false
                    }
                }
            )
        ) {
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
        } message: {
            if isShowingServerActionError {
                Text(viewModel.serverActionErrorMessage ?? "다시 시도해 주세요.")
            } else {
                Text("준비가 되면 다음 세트를 시작해 주세요.")
            }
        }
        .onChange(of: viewModel.currentExerciseIndex) { _, _ in
            isShowingCurrentGuide = false
            showFirstExercisePromptIfNeeded()
        }
        .onChange(of: viewModel.finishedAt) { _, finishedAt in
            guard finishedAt != nil else { return }
            settings.cancelRestNotification(sessionID: liveActivitySessionID)
            Task { await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID) }
        }
        .task { showFirstExercisePromptIfNeeded() }
        .task(id: "\(viewModel.hasStarted)-\(viewModel.currentExercise?.id ?? "")") {
            guard viewModel.hasStarted, let exerciseID = viewModel.currentExercise?.id else { return }
            await loadPreviousRecord(for: exerciseID)
        }
    }

}

#Preview {
    NavigationStack {
        WorkoutSessionView(routineID: "upper-a", historyStore: HistoryStore())
    }
    .preferredColorScheme(.dark)
}
