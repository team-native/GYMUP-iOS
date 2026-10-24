import Combine
import SwiftUI

struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WorkoutSessionViewModel
    @State private var isConfirmingFinish = false
    @State private var isShowingWorkoutPhoto = false
    @State private var photoCompletionData: WorkoutCompletionData?
    @State private var guideIndex = 0
    @State private var isShowingCurrentGuide = false

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(routineID: String) {
        _viewModel = State(initialValue: WorkoutSessionViewModel(routineID: routineID, startsImmediately: false))
    }

    var body: some View {
        Group {
            if let data = viewModel.completionData {
                WorkoutCompletionFlowView(
                    data: data,
                    onWorkoutPhoto: {
                        photoCompletionData = data
                        isShowingWorkoutPhoto = true
                    },
                    onFinish: dismiss.callAsFunction,
                    showsPhotoAction: true
                )
            } else if !viewModel.hasStarted {
                preparationContent
            } else {
                sessionContent
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingWorkoutPhoto, onDismiss: { photoCompletionData = nil }) {
            if let photoCompletionData {
                WorkoutPhotoFlowView(data: photoCompletionData) {
                    isShowingWorkoutPhoto = false
                }
                .presentationDragIndicator(.visible)
            }
        }
        .onReceive(clock) { viewModel.refreshClock(at: $0) }
        .confirmationDialog(
            "운동을 마칠까요?",
            isPresented: $isConfirmingFinish,
            titleVisibility: .visible
        ) {
            Button("계속 운동하기", role: .cancel) {}
            Button("완료 화면 보기") { viewModel.finish() }
        } message: {
            Text("현재까지 기록한 세트 결과로 운동을 마무리합니다.")
        }
        .onChange(of: viewModel.currentExerciseIndex) { _, _ in
            isShowingCurrentGuide = false
        }
    }

    private var preparationContent: some View {
        WorkoutSessionPreparationView(
            plan: viewModel.plan,
            selectedExerciseIndex: $guideIndex,
            onBack: dismiss.callAsFunction,
            onStart: { viewModel.start(at: Date()) }
        )
    }

    private var sessionContent: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: GymupSpacing.large) {
                    WorkoutSessionProgressCard(
                        title: viewModel.plan.title,
                        completedCount: viewModel.completedExerciseCount,
                        totalCount: viewModel.plan.exercises.count
                    )

                    if let exercise = viewModel.currentExercise {
                        WorkoutSessionExerciseCard(
                            exercise: exercise,
                            exerciseIndex: viewModel.currentExerciseIndex,
                            totalExercises: viewModel.plan.exercises.count,
                            isShowingGuide: $isShowingCurrentGuide,
                            onToggleGuide: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isShowingCurrentGuide.toggle()
                                }
                            },
                            onAddSet: { viewModel.addSet(to: viewModel.currentExerciseIndex) },
                            onToggleSet: { setIndex in
                                viewModel.toggleSetCompletion(
                                    exerciseIndex: viewModel.currentExerciseIndex,
                                    setIndex: setIndex,
                                    at: Date()
                                )
                            },
                            weightBinding: { weightBinding(exerciseIndex: viewModel.currentExerciseIndex, setIndex: $0) },
                            repetitionsBinding: {
                                repetitionsBinding(exerciseIndex: viewModel.currentExerciseIndex, setIndex: $0)
                            }
                        )
                        if viewModel.isResting || viewModel.isPaused {
                            WorkoutSessionRestCard(
                                isPaused: viewModel.isPaused,
                                remainingSeconds: viewModel.restSecondsRemaining,
                                onSkip: viewModel.skipRest
                            )
                        }
                    }

                    if let notice = viewModel.notice {
                        Label(notice, systemImage: "info.circle.fill")
                            .font(GymupTypography.callout)
                            .foregroundStyle(GymupColors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(GymupSpacing.medium)
                            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, GymupSpacing.large)
                .padding(.bottom, GymupSpacing.large)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar
        }
    }

    private var header: some View {
        HStack(spacing: GymupSpacing.medium) {
            Button {
                isConfirmingFinish = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("운동 종료 확인")

            VStack(alignment: .leading, spacing: 2) {
                Text("운동 중")
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                Text(viewModel.plan.name)
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
            }

            Spacer(minLength: GymupSpacing.small)

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedDuration(viewModel.elapsedSeconds))
                    .font(.system(.title3, design: .rounded).monospacedDigit().weight(.bold))
                    .foregroundStyle(GymupColors.primaryText)
                    .accessibilityLabel("운동 시간 \(spokenDuration(viewModel.elapsedSeconds))")
                Button(viewModel.isPaused ? "이어 하기" : "일시 정지") {
                    viewModel.togglePause(at: Date())
                }
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.accent)
                .frame(minHeight: 44)
                .accessibilityIdentifier("workout.pause")
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .frame(height: 60)
        .background(GymupColors.canvas)
    }

    private var actionBar: some View {
        VStack(spacing: GymupSpacing.small) {
            if viewModel.currentExerciseIndex < viewModel.plan.exercises.count - 1 {
                GymupButton(title: "다음 운동", height: 52) {
                    viewModel.moveToNextExercise()
                }
                .accessibilityIdentifier("workout.next-exercise")
            } else {
                GymupButton(title: "운동 마치기", height: 52) {
                    isConfirmingFinish = true
                }
                .accessibilityIdentifier("workout.finish")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, GymupSpacing.medium)
        .padding(.bottom, GymupSpacing.small)
        .background(GymupColors.canvas)
    }

    private func weightBinding(exerciseIndex: Int, setIndex: Int) -> Binding<Double> {
        Binding(
            get: { viewModel.plan.exercises[exerciseIndex].sets[setIndex].weightKilograms },
            set: { viewModel.updateWeight($0, exerciseIndex: exerciseIndex, setIndex: setIndex) }
        )
    }

    private func repetitionsBinding(exerciseIndex: Int, setIndex: Int) -> Binding<Int> {
        Binding(
            get: { viewModel.plan.exercises[exerciseIndex].sets[setIndex].repetitions },
            set: { viewModel.updateRepetitions($0, exerciseIndex: exerciseIndex, setIndex: setIndex) }
        )
    }

    private func formattedDuration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func spokenDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes == 0 { return "\(remainder)초" }
        return remainder == 0 ? "\(minutes)분" : "\(minutes)분 \(remainder)초"
    }
}

#Preview {
    NavigationStack {
        WorkoutSessionView(routineID: "upper-a")
    }
    .preferredColorScheme(.dark)
}
