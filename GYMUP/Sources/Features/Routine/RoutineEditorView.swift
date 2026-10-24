import SwiftUI
import UniformTypeIdentifiers

struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool
    @State private var viewModel: RoutineEditorViewModel
    @State private var isAddExercisePresented = false

    let onSave: (String) -> Void
    let onSelectExercise: (String) -> Void

    init(store: RoutineStore, routineID: String?, onSave: @escaping (String) -> Void,
         onSelectExercise: @escaping (String) -> Void) {
        _viewModel = State(initialValue: RoutineEditorViewModel(store: store, routineID: routineID))
        self.onSave = onSave
        self.onSelectExercise = onSelectExercise
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    nameInput
                    exerciseList
                    addExerciseButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.title) { _, newValue in viewModel.limitTitle(newValue) }
        .onDisappear { viewModel.draggingExerciseID = nil }
        .overlay { addExerciseOverlay }
    }

    private var navigationBar: some View {
        HStack {
            Button(action: dismiss.callAsFunction) {
                Image("R3IconClose")
                    .resizable()
                    .frame(width: 22, height: 22)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("닫기")
            Spacer()
            Text(viewModel.routineID == nil ? "루틴 만들기" : "루틴 편집")
                .font(GymupTypography.uiStrong)
                .foregroundStyle(GymupColors.primaryText)
            Spacer()
            Button {
                guard let id = viewModel.save() else { return }
                onSave(id)
            } label: {
                Text("저장")
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.brandText)
                    .frame(width: 64, height: 40)
            }
            .disabled(!viewModel.canSave)
            .opacity(viewModel.canSave ? 1 : 0.45)
            .accessibilityIdentifier("routine.editor.save")
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .frame(height: 48)
    }

    private var nameInput: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("루틴 이름")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
            HStack(alignment: .firstTextBaseline) {
                TextField("루틴 이름", text: $viewModel.title)
                    .font(GymupTypography.homeTitle)
                    .foregroundStyle(GymupColors.primaryText)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit { isNameFocused = false }
                    .accessibilityIdentifier("routine.editor.name")
                Text("\(viewModel.title.count)/20")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.tertiaryText)
                    .accessibilityIdentifier("routine.editor.name-count")
            }
            .padding(.bottom, 10)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isNameFocused ? GymupColors.accent : GymupColors.border)
                    .frame(height: isNameFocused ? 2 : 1)
            }
        }
    }

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("운동 \(viewModel.exerciseCount)")
                    .font(GymupTypography.sectionTitle)
                    .foregroundStyle(GymupColors.primaryText)
                Spacer()
                Text("길게 눌러 순서 변경")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
            }

            VStack(spacing: 0) {
                ForEach(viewModel.exercises) { exercise in
                    exerciseRow(exercise)
                        .onDrag {
                            viewModel.draggingExerciseID = exercise.id
                            return NSItemProvider(object: exercise.id as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: RoutineExerciseReorderDelegate(
                                item: exercise,
                                exercises: $viewModel.exercises,
                                draggingExerciseID: $viewModel.draggingExerciseID
                            )
                        )
                }
            }
        }
    }

    private func exerciseRow(_ exercise: RoutineExercise) -> some View {
        let isDragging = viewModel.draggingExerciseID == exercise.id
        return Button { onSelectExercise(exercise.id) } label: {
            HStack(spacing: 14) {
                Image(exercise.imageAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                    Text(exercise.summary)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image("R3IconGrip")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, isDragging ? 12 : 0)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isDragging {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GymupColors.elevatedSurface)
                }
            }
            .overlay {
                if isDragging {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(GymupColors.accent, lineWidth: 1.5)
                        .shadow(color: .black.opacity(0.5), radius: 12, y: 8)
                }
            }
            .overlay(alignment: .bottom) {
                if !isDragging {
                    Rectangle()
                        .fill(GymupColors.border)
                        .frame(height: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(exercise.name), \(exercise.summary), 길게 눌러 순서 변경")
        .accessibilityIdentifier("routine.editor.exercise.\(exercise.id)")
    }

    private var addExerciseButton: some View {
        Button { isAddExercisePresented = true } label: {
            HStack(spacing: 6) {
                Image("R3IconPlus")
                    .resizable()
                    .frame(width: 16, height: 16)
                Text("운동 추가")
                    .font(GymupTypography.uiMedium)
                    .foregroundStyle(GymupColors.primaryText)
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .overlay(Capsule().strokeBorder(GymupColors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("routine.editor.add-exercise")
    }

    @ViewBuilder
    private var addExerciseOverlay: some View {
        if isAddExercisePresented {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture { isAddExercisePresented = false }
                    RoutineAddExerciseView(exercises: $viewModel.exercises) {
                        isAddExercisePresented = false
                    }
                    .frame(height: geometry.size.height * 0.77)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                    .transition(.move(edge: .bottom))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.2), value: isAddExercisePresented)
        }
    }
}

private struct RoutineExerciseReorderDelegate: DropDelegate {
    let item: RoutineExercise
    @Binding var exercises: [RoutineExercise]
    @Binding var draggingExerciseID: String?

    func dropEntered(info: DropInfo) {
        guard let draggingExerciseID, draggingExerciseID != item.id,
              let source = exercises.firstIndex(where: { $0.id == draggingExerciseID }),
              let target = exercises.firstIndex(where: { $0.id == item.id }) else { return }
        let destination = source < target ? target - 1 : target
        guard destination != source else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            let movingExercise = exercises.remove(at: source)
            exercises.insert(movingExercise, at: destination)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        draggingExerciseID = nil
        return true
    }
}

#Preview {
    RoutineEditorView(store: RoutineStore(), routineID: "upper-a", onSave: { _ in },
                      onSelectExercise: { _ in })
        .preferredColorScheme(.dark)
}
