import SwiftUI

struct RoutineView: View {
    let onDetailRouteChanged: (Bool) -> Void
    @State private var viewModel: RoutineViewModel
    @State private var path: [RoutineRoute] = []
    @State private var isDuplicateToastVisible = false
    @State private var duplicateToastVersion = 0
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
                        onDuplicate: { _ in
                            path.removeAll()
                            duplicateToastVersion += 1
                            isDuplicateToastVisible = true
                        },
                        onDelete: {
                            if path.last == .detail(id) { path.removeLast() }
                        },
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
    RoutineView(store: RoutineStore())
        .preferredColorScheme(.dark)
}
