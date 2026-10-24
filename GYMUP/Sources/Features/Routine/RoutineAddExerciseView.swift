import SwiftUI

struct RoutineAddExerciseView: View {
    @Binding private var exercises: [RoutineExercise]
    @State private var viewModel: RoutineAddExerciseViewModel
    @FocusState private var isSearchFocused: Bool

    let onClose: () -> Void

    private let categories = ["전체", "가슴", "등", "하체", "어깨"]

    init(exercises: Binding<[RoutineExercise]>, onClose: @escaping () -> Void) {
        self._exercises = exercises
        _viewModel = State(initialValue: RoutineAddExerciseViewModel(existingExercises: exercises.wrappedValue))
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 20) {
            header
            searchField
            categoryFilters
            exerciseOptions
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GymupColors.surface)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GymupButton(
                title: "\(viewModel.selectedCount)개 추가",
                isEnabled: viewModel.selectedCount > 0,
                font: GymupTypography.sectionTitle,
                height: 50,
                cornerRadius: 25
            ) {
                exercises.append(contentsOf: viewModel.exercisesToAdd())
                isSearchFocused = false
                onClose()
            }
            .accessibilityIdentifier("routine.add-exercise.confirm")
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(GymupColors.surface)
        }
        .overlay(alignment: .top) {
            Capsule()
                .fill(GymupColors.overlay)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
        }
    }

    private var header: some View {
        HStack {
            Text("운동 추가")
                .font(GymupTypography.homeTitle)
                .foregroundStyle(GymupColors.primaryText)
            Spacer()
            Button(action: onClose) {
                Image("R3IconClose")
                    .resizable()
                    .frame(width: 22, height: 22)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("닫기")
        }
        .frame(height: 32)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image("R4IconSearch")
                .resizable()
                .frame(width: 20, height: 20)
            TextField("운동 검색", text: $viewModel.searchText)
                .font(GymupTypography.uiBody)
                .foregroundStyle(GymupColors.primaryText)
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("routine.add-exercise.search")
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 10))
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    GymupFilterChip(title: category, isSelected: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
        .contentMargins(.trailing, 1)
    }

    private var exerciseOptions: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.visibleOptions) { option in
                    optionRow(option)
                }
                if viewModel.visibleOptions.isEmpty {
                    GymupEmptyState(symbol: "magnifyingglass", title: "운동을 찾을 수 없어요", message: "다른 이름으로 검색해 주세요.")
                        .padding(.top, 32)
                }
            }
        }
    }

    private func optionRow(_ option: RoutineExerciseOption) -> some View {
        let isSelected = viewModel.isSelected(option)
        return Button { viewModel.toggle(option) } label: {
            HStack(spacing: 14) {
                Image(option.exercise.imageAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.exercise.name)
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                    Text(option.descriptor)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                selectionMark(isSelected)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(GymupColors.border)
                    .frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.exercise.name), \(option.descriptor)")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityIdentifier("routine.add-exercise.option.\(option.id)")
    }

    @ViewBuilder
    private func selectionMark(_ isSelected: Bool) -> some View {
        if isSelected {
            Image("R4IconCheck")
                .resizable()
                .frame(width: 14, height: 14)
                .frame(width: 24, height: 24)
                .background(GymupColors.accent, in: Circle())
        } else {
            Circle()
                .strokeBorder(GymupColors.strongBorder, lineWidth: 1.5)
                .frame(width: 24, height: 24)
        }
    }
}

#Preview {
    RoutineAddExerciseView(exercises: .constant([]), onClose: {})
        .preferredColorScheme(.dark)
}
