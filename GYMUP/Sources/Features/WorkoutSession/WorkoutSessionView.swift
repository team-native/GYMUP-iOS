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

    let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
}

#Preview {
    NavigationStack {
        WorkoutSessionView(routineID: "upper-a", historyStore: HistoryStore())
    }
    .preferredColorScheme(.dark)
}
