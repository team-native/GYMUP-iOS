import SwiftUI

struct RoutineExerciseSettingsView: View {
    @State private var viewModel: RoutineExerciseSettingsViewModel

    let onApply: (RoutineExercise) -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    init(exercise: RoutineExercise, onApply: @escaping (RoutineExercise) -> Void,
         onDelete: @escaping () -> Void, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: RoutineExerciseSettingsViewModel(exercise: exercise))
        self.onApply = onApply
        self.onDelete = onDelete
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 4) {
            exerciseHeader
            RoutineExerciseSettingStepper(
                title: "세트",
                value: String(viewModel.exercise.setCount),
                unit: "SETS",
                onDecrease: { viewModel.adjustSets(by: -1) },
                onIncrease: { viewModel.adjustSets(by: 1) }
            )
            RoutineExerciseSettingStepper(
                title: viewModel.exercise.measure == .seconds ? "시간" : "횟수",
                value: String(viewModel.exercise.repetitions),
                unit: viewModel.exercise.measure == .seconds ? "SECS" : "REPS",
                onDecrease: { viewModel.adjustRepetitions(by: -1) },
                onIncrease: { viewModel.adjustRepetitions(by: 1) }
            )
            RoutineExerciseSettingStepper(
                title: "무게",
                subtitle: "2.5kg 단위",
                value: viewModel.exercise.weightTitle,
                unit: "KG",
                onDecrease: { viewModel.adjustWeight(by: -2.5) },
                onIncrease: { viewModel.adjustWeight(by: 2.5) }
            )
            RoutineExerciseSettingStepper(
                title: "휴식",
                subtitle: "기본값",
                value: viewModel.exercise.restTitle,
                unit: "REST",
                onDecrease: { viewModel.adjustRest(by: -30) },
                onIncrease: { viewModel.adjustRest(by: 30) }
            )
            Spacer(minLength: 4)
            actionButtons
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GymupColors.surface)
        .gesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    if value.translation.height > 60 { onClose() }
                }
        )
        .overlay(alignment: .top) {
            Capsule()
                .fill(GymupColors.overlay)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
        }
    }

    private var exerciseHeader: some View {
        HStack(spacing: 14) {
            Image(viewModel.exercise.imageAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.exercise.name)
                    .font(GymupTypography.sectionTitle)
                    .foregroundStyle(GymupColors.primaryText)
                Text(exerciseDescription)
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 8)
    }

    private var exerciseDescription: String {
        switch viewModel.exercise.id {
        case "bench": "바벨 · 가슴 · 삼두"
        case "incline": "덤벨 · 윗가슴"
        case "fly": "케이블 · 가슴"
        case "dips": "맨몸 · 가슴 하부"
        case "shoulder": "덤벨 · 어깨"
        default: viewModel.exercise.resistanceTitle
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(action: onDelete) {
                Text("삭제")
                    .font(GymupTypography.sectionTitle)
                    .foregroundStyle(GymupColors.critical)
                    .frame(width: 100, height: 50)
                    .background(GymupColors.elevatedSurface, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("routine.exercise-settings.delete")
            GymupButton(title: "적용", font: GymupTypography.sectionTitle, height: 50, cornerRadius: 25) {
                onApply(viewModel.exercise)
            }
            .accessibilityIdentifier("routine.exercise-settings.apply")
        }
    }
}

private struct RoutineExerciseSettingStepper: View {
    let title: String
    var subtitle: String?
    let value: String
    let unit: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                if let subtitle {
                    Text(subtitle)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(GymupTypography.metric)
                    .tracking(0.13)
                    .foregroundStyle(GymupColors.primaryText)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("routine.exercise-settings.value.\(title)")
                Text(unit)
                    .font(GymupTypography.label)
                    .tracking(0.17)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            .frame(minWidth: 54, alignment: .trailing)
            stepper
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(GymupColors.border)
                .frame(height: 1)
        }
    }

    private var stepper: some View {
        HStack(spacing: 0) {
            stepperButton("−", action: onDecrease)
            Rectangle()
                .fill(GymupColors.strongBorder)
                .frame(width: 1)
            stepperButton("+", action: onIncrease)
        }
        .frame(width: 94, height: 32)
        .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func stepperButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("GothicA1-Regular", size: 20))
                .foregroundStyle(GymupColors.primaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(self.title) \(title == "+" ? "증가" : "감소")")
    }
}

#Preview {
    RoutineExerciseSettingsView(exercise: RoutineExercise.upper[0], onApply: { _ in }, onDelete: {}, onClose: {})
        .preferredColorScheme(.dark)
}
