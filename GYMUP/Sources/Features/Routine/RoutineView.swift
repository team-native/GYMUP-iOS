import SwiftUI

struct RoutineView: View {
    let onDetailRouteChanged: (Bool) -> Void
    let onEmptyStartAttempt: (String) -> Void
    private let historyStore: HistoryStore
    @State private var viewModel: RoutineViewModel
    @State private var path: [RoutineRoute] = []
    @State private var isDuplicateToastVisible = false
    @State private var isUnsupportedWorkoutPresented = false
    @State private var duplicateToastVersion = 0
    @Binding private var requestedRoutineID: String?
    @Binding private var requestedExerciseAddRoutineID: String?

    @MainActor
    init(store: RoutineStore, historyStore: HistoryStore, requestedRoutineID: Binding<String?> = .constant(nil),
         requestedExerciseAddRoutineID: Binding<String?> = .constant(nil),
         onEmptyStartAttempt: @escaping (String) -> Void = { _ in },
         onDetailRouteChanged: @escaping (Bool) -> Void = { _ in }) {
        _viewModel = State(initialValue: RoutineViewModel(store: store))
        self.historyStore = historyStore
        self.onDetailRouteChanged = onDetailRouteChanged
        self.onEmptyStartAttempt = onEmptyStartAttempt
        self._requestedRoutineID = requestedRoutineID
        self._requestedExerciseAddRoutineID = requestedExerciseAddRoutineID
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header
                    .padding(.top, 4)
                GymupSegmentedControl(selection: $viewModel.mode)
                .frame(height: 32)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.routines) { routine in
                            if routine.isEmpty {
                                EmptyRoutineCard(
                                    onOpen: { path.append(.edit(routine.id)) },
                                    onStart: { onEmptyStartAttempt(routine.id) }
                                )
                            } else {
                                RoutineCard(
                                    routine: routine,
                                    onOpen: { path.append(.detail(routine.id)) },
                                    onStart: { startWorkout(routine.id) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(GymupColors.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: RoutineRoute.self) { route in
                switch route {
                case .detail(let id):
                    RoutineDetailView(
                        store: viewModel.store,
                        routineID: id,
                        onEdit: { path.append(.edit(id)) },
                        onDuplicate: { _ in
                            path.removeAll()
                            duplicateToastVersion += 1
                            isDuplicateToastVisible = true
                        },
                        onDelete: {
                            if path.last == .detail(id) { path.removeLast() }
                        },
                        onStart: { startWorkout(id) }
                    )
                case .create:
                    routineEditor(routineID: nil)
                case .edit(let id):
                    routineEditor(routineID: id)
                case .editAndAddExercise(let id):
                    routineEditor(routineID: id, opensAddExerciseOnAppear: true)
                case .workout(let routineID):
                    if let routine = viewModel.store.routine(id: routineID),
                       let plan = WorkoutSessionPlan.make(from: routine) {
                        WorkoutSessionView(plan: plan, historyStore: historyStore)
                    } else {
                        GymupEmptyState(symbol: "dumbbell", title: "루틴을 열 수 없어요", message: "루틴 내용을 확인해 주세요.")
                    }
                default:
                    RoutinePendingView(route: route)
                }
            }
        }
        .alert("운동을 시작할 수 없어요", isPresented: $isUnsupportedWorkoutPresented) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("시간 단위 운동은 아직 세션에서 지원하지 않아요. 운동 설정을 확인해 주세요.")
        }
        .overlay(alignment: .bottom) {
            if isDuplicateToastVisible {
                RoutineDuplicateToast()
                    .padding(.bottom, 34)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: duplicateToastVersion) {
            guard duplicateToastVersion > 0 else { return }
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch {
                return
            }
            isDuplicateToastVisible = false
        }
        .onChange(of: path) { _, newPath in onDetailRouteChanged(!newPath.isEmpty) }
        .onAppear {
            openRequestedRoutine()
            openRequestedExerciseAdd()
            onDetailRouteChanged(!path.isEmpty)
        }
        .onChange(of: requestedRoutineID) { _, _ in openRequestedRoutine() }
        .onChange(of: requestedExerciseAddRoutineID) { _, _ in openRequestedExerciseAdd() }
    }

    private func startWorkout(_ id: String) {
        guard let routine = viewModel.store.routine(id: id) else { return }
        if routine.isEmpty || routine.exercises.isEmpty {
            onEmptyStartAttempt(id)
        } else if WorkoutSessionPlan.make(from: routine) == nil {
            isUnsupportedWorkoutPresented = true
        } else {
            path.append(.workout(id))
        }
    }

    private func openRequestedRoutine() {
        guard let id = requestedRoutineID else { return }
        requestedRoutineID = nil
        if viewModel.store.routine(id: id) != nil { path.append(.detail(id)) }
    }

    private func openRequestedExerciseAdd() {
        guard let id = requestedExerciseAddRoutineID else { return }
        requestedExerciseAddRoutineID = nil
        guard viewModel.store.routine(id: id) != nil else { return }
        path = [.editAndAddExercise(id)]
    }

    private func routineEditor(routineID: String?, opensAddExerciseOnAppear: Bool = false) -> some View {
        RoutineEditorView(
            store: viewModel.store,
            routineID: routineID,
            opensAddExerciseOnAppear: opensAddExerciseOnAppear,
            onSave: { savedID in
                if !path.isEmpty { path.removeLast() }
                if path.isEmpty { path.append(.detail(savedID)) }
            }
        )
    }

    private var header: some View {
        HStack {
            Text("루틴")
                .font(GymupTypography.homeTitle)
                .tracking(-0.43)
                .foregroundStyle(GymupColors.primaryText)
            Spacer()
            Button { path.append(.create) } label: {
                Image("R1IconPlus")
                    .resizable()
                    .frame(width: 16.4, height: 16.4)
                    .frame(width: 32.8, height: 32.8)
                    .background(GymupColors.accent, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("루틴 추가")
            .accessibilityIdentifier("routine.add")
        }
        .padding(.horizontal, 20)
        .frame(height: 48)
    }
}

private struct RoutineDuplicateToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(GymupColors.brandText)
            Text("루틴을 복제했어요")
                .font(GymupTypography.uiMedium)
                .foregroundStyle(GymupColors.primaryText)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(GymupColors.overlay, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
        .accessibilityIdentifier("routine.duplicate.toast")
        .allowsHitTesting(false)
    }
}

#Preview {
    RoutineView(store: RoutineStore(), historyStore: HistoryStore())
        .preferredColorScheme(.dark)
}
