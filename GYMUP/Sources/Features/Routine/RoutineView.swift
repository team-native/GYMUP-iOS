import SwiftUI

struct RoutineView: View {
    @State private var viewModel = RoutineViewModel()

    private var filteredRoutines: [RoutinePlan] {
        viewModel.routines.filter(viewModel.matchesCategory)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                    VStack(alignment: .leading, spacing: GymupSpacing.small) {
                        Text("내 루틴")
                            .font(GymupTypography.largeTitle)
                        Text("오늘의 컨디션에 맞춰 운동을 시작해요")
                            .font(GymupTypography.callout)
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    categoryPicker
                    VStack(spacing: GymupSpacing.medium) {
                        ForEach(filteredRoutines) { routine in
                            NavigationLink(value: routine) {
                                RoutineCard(routine: routine)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button {} label: {
                        Label("새 루틴 만들기", systemImage: "plus")
                            .font(GymupTypography.callout.weight(.semibold))
                            .foregroundStyle(GymupColors.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, GymupSpacing.large)
                            .overlay(RoundedRectangle(cornerRadius: GymupRadius.medium).stroke(GymupColors.separator))
                    }
                }
                .padding(GymupSpacing.large)
            }
            .background(GymupColors.canvas)
            .navigationDestination(for: RoutinePlan.self) { routine in
                RoutineDetailView(routine: routine)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GymupSpacing.small) {
                ForEach(viewModel.categories, id: \.self) { category in
                    Button {
                        viewModel.selectedCategory = category
                    } label: {
                        Text(category)
                            .font(GymupTypography.caption.weight(.semibold))
                            .foregroundStyle(viewModel.selectedCategory == category ? .white : GymupColors.secondaryText)
                            .padding(.horizontal, GymupSpacing.medium)
                            .padding(.vertical, GymupSpacing.small)
                            .background(
                                viewModel.selectedCategory == category ? GymupColors.accent : GymupColors.surface,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct RoutineCard: View {
    let routine: RoutinePlan

    var body: some View {
        HStack(spacing: GymupSpacing.medium) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(GymupColors.accent)
                .frame(width: 54, height: 54)
                .background(GymupColors.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                Text(routine.name).font(GymupTypography.headline)
                Text(routine.focus).font(GymupTypography.caption).foregroundStyle(GymupColors.secondaryText)
                Text("\(routine.exerciseCount)개 운동  ·  약 \(routine.durationMinutes)분")
                    .font(GymupTypography.caption).foregroundStyle(GymupColors.secondaryText)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(GymupColors.secondaryText)
        }
        .foregroundStyle(GymupColors.primaryText)
        .padding(GymupSpacing.medium)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
    }
}

private struct RoutineDetailView: View {
    let routine: RoutinePlan
    @State private var isWorkoutPresented = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: GymupSpacing.large) {
                    VStack(alignment: .leading, spacing: GymupSpacing.small) {
                        Text(routine.name).font(GymupTypography.largeTitle)
                        Text("\(routine.focus)  ·  \(routine.durationMinutes)분")
                            .font(GymupTypography.callout).foregroundStyle(GymupColors.secondaryText)
                    }
                    ForEach(Array(routine.exercises.enumerated()), id: \.element.id) { index, exercise in
                        HStack(spacing: GymupSpacing.medium) {
                            Text(String(format: "%02d", index + 1))
                                .font(GymupTypography.caption.weight(.bold).monospacedDigit())
                                .foregroundStyle(GymupColors.accent)
                                .frame(width: 34)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name).font(GymupTypography.callout.weight(.semibold))
                                Text(exercise.detail).font(GymupTypography.caption).foregroundStyle(GymupColors.secondaryText)
                            }
                            Spacer()
                            Text(exercise.weight).font(GymupTypography.caption).foregroundStyle(GymupColors.secondaryText)
                        }
                        .padding(GymupSpacing.medium)
                        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
                    }
                }
                .padding(GymupSpacing.large)
            }
            GymupButton(title: "운동 시작하기") { isWorkoutPresented = true }
                .padding(GymupSpacing.large)
                .background(GymupColors.canvas)
        }
        .background(GymupColors.canvas)
        .foregroundStyle(GymupColors.primaryText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $isWorkoutPresented) {
            WorkoutSessionView(routine: routine)
        }
    }
}

#Preview {
    RoutineView()
}
