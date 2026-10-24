import SwiftUI

struct RoutineDetailView: View {
    let onEdit: () -> Void
    let onDuplicate: (String) -> Void
    let onDelete: () -> Void
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RoutineDetailViewModel

    init(store: RoutineStore, routineID: String, onEdit: @escaping () -> Void,
         onDuplicate: @escaping (String) -> Void, onDelete: @escaping () -> Void,
         onStart: @escaping () -> Void) {
        _viewModel = State(initialValue: RoutineDetailViewModel(store: store, routineID: routineID))
        self.onEdit = onEdit
        self.onDuplicate = onDuplicate
        self.onDelete = onDelete
        self.onStart = onStart
    }

    var body: some View {
        ZStack(alignment: .top) {
            GymupColors.canvas.ignoresSafeArea()
            if let routine = viewModel.routine {
                heroBackground(routine.coverAssetName)
            }
            VStack(spacing: 0) {
                navigationBar
                if let routine = viewModel.routine {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            heroSummary(routine)
                                .padding(.top, 56)
                                .padding(.bottom, 30)
                            muscleGroups(routine)
                                .padding(.bottom, 8)
                            ForEach(routine.exercises) { exercise in
                                RoutineExerciseRow(exercise: exercise)
                            }
                            playlist
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                } else {
                    GymupEmptyState(symbol: "dumbbell", title: "루틴을 찾을 수 없어요", message: "목록으로 돌아가 루틴을 선택해 주세요.")
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.routine != nil { actions }
        }
        .confirmationDialog(
            "루틴 더보기",
            isPresented: $viewModel.isMoreActionsPresented,
            titleVisibility: .visible
        ) {
            Button("편집", action: onEdit)
                .accessibilityIdentifier("routine.more.edit")
            Button("복제") {
                if let duplicateID = viewModel.duplicateRoutine() {
                    onDuplicate(duplicateID)
                }
            }
            .accessibilityIdentifier("routine.more.duplicate")
            Button("삭제", role: .destructive) {
                viewModel.deleteRoutine()
                onDelete()
            }
            .accessibilityIdentifier("routine.more.delete")
            Button("취소", role: .cancel) {}
                .accessibilityIdentifier("routine.more.cancel")
        }
    }

    private var navigationBar: some View {
        HStack {
            Button(action: dismiss.callAsFunction) {
                Image("GymupIconChevronLeft").resizable().frame(width: 24, height: 24)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("뒤로")
            Spacer()
            Button(action: viewModel.presentMoreActions) {
                Image("R2IconMore").resizable().frame(width: 22, height: 22)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("루틴 더보기")
            .accessibilityIdentifier("routine.detail.more")
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .frame(height: 48)
    }

    private func heroBackground(_ assetName: String) -> some View {
        GeometryReader { geometry in
            Image(assetName)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: 206 + geometry.safeAreaInsets.top)
                .clipped()
                .overlay {
                    LinearGradient(stops: [
                        .init(color: GymupColors.canvas.opacity(0.3), location: 0.2),
                        .init(color: GymupColors.canvas, location: 1)
                    ], startPoint: .top, endPoint: .bottom)
                }
                .offset(y: -geometry.safeAreaInsets.top)
        }
        .allowsHitTesting(false)
    }

    private func heroSummary(_ routine: RoutinePlan) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(routine.name)
                .font(GymupTypography.routineTitle)
                .tracking(-0.28)
                .foregroundStyle(GymupColors.primaryText)
                .frame(height: 36)
            Text(viewModel.summary)
                .font(GymupTypography.uiMedium)
                .foregroundStyle(GymupColors.secondaryText)
                .frame(minHeight: 19)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private func muscleGroups(_ routine: RoutinePlan) -> some View {
        HStack(spacing: 8) {
            ForEach(routine.muscleGroups, id: \.self) { group in
                Text(group)
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(height: 15)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(GymupColors.elevatedSurface, in: Capsule())
            }
        }
    }

    private var playlist: some View {
        HStack(spacing: 12) {
            Image("R2IconMusic").resizable().frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text("플레이리스트 연결")
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(minHeight: 21)
                Text("PLAYLIST-001 · V2 예정")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.tertiaryText)
                    .frame(minHeight: 15)
            }
            Spacer()
            Image("H3IconChevronRight").resizable().frame(width: 18, height: 18)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(GymupColors.border).frame(height: 1)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            GymupButton(title: "편집", variant: .elevated, font: GymupTypography.sectionTitle,
                        height: 50, cornerRadius: 999, action: onEdit)
                .frame(width: 80)
            GymupButton(title: "운동 시작", font: GymupTypography.sectionTitle,
                        height: 50, cornerRadius: 999, action: onStart)
        }
        .padding(.horizontal, 36)
        .background(GymupColors.canvas)
    }
}
