import SwiftUI

struct RoutineView: View {
    let onDetailRouteChanged: (Bool) -> Void
    @State private var viewModel: RoutineViewModel
    @State private var path: [RoutineRoute] = []
    @Binding private var requestedRoutineID: String?

    init(store: RoutineStore, requestedRoutineID: Binding<String?> = .constant(nil),
         onDetailRouteChanged: @escaping (Bool) -> Void = { _ in }) {
        _viewModel = State(initialValue: RoutineViewModel(store: store))
        self.onDetailRouteChanged = onDetailRouteChanged
        self._requestedRoutineID = requestedRoutineID
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
                                    onStart: { path.append(.emptyStart(routine.id)) }
                                )
                            } else {
                                RoutineCard(
                                    routine: routine,
                                    onOpen: { path.append(.detail(routine.id)) },
                                    onStart: { path.append(.workout(routine.id)) }
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
                        onMore: { path.append(.more(id)) },
                        onStart: {
                            path.append(viewModel.store.routine(id: id)?.isEmpty == true ? .emptyStart(id) : .workout(id))
                        }
                    )
                case .create:
                    routineEditor(routineID: nil)
                case .edit(let id):
                    routineEditor(routineID: id)
                case .workout(let routineID):
                    WorkoutSessionView(routineID: routineID)
                default:
                    RoutinePendingView(route: route)
                }
            }
        }
        .onChange(of: path) { _, newPath in onDetailRouteChanged(!newPath.isEmpty) }
        .onAppear {
            openRequestedRoutine()
            onDetailRouteChanged(!path.isEmpty)
        }
        .onChange(of: requestedRoutineID) { _, _ in openRequestedRoutine() }
    }

    private func openRequestedRoutine() {
        guard let id = requestedRoutineID else { return }
        requestedRoutineID = nil
        if viewModel.store.routine(id: id) != nil { path.append(.detail(id)) }
    }

    private func routineEditor(routineID: String?) -> some View {
        RoutineEditorView(
            store: viewModel.store,
            routineID: routineID,
            onSave: { savedID in
                if !path.isEmpty { path.removeLast() }
                if path.isEmpty { path.append(.detail(savedID)) }
            },
            onAddExercise: { path.append(.addExercise($0)) },
            onSelectExercise: { path.append(.exerciseSettings(routineID ?? "new", $0)) }
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

#Preview {
    RoutineView(store: RoutineStore())
        .preferredColorScheme(.dark)
}
