import SwiftUI

struct RoutineEditorNameInput: View {
    @Binding var title: String
    @FocusState.Binding var isFocused: Bool
    let showsError: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("루틴 이름")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(showsError ? GymupColors.critical : GymupColors.secondaryText)
            HStack(alignment: .firstTextBaseline) {
                TextField(showsError ? "루틴 이름을 입력하세요" : "루틴 이름", text: $title)
                    .font(GymupTypography.homeTitle)
                    .foregroundStyle(GymupColors.primaryText)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit { isFocused = false }
                    .accessibilityIdentifier("routine.editor.name")
                if !showsError {
                    Text("\(title.count)/20")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.tertiaryText)
                        .accessibilityIdentifier("routine.editor.name-count")
                }
            }
            .padding(.bottom, 10)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(showsError ? GymupColors.critical : (isFocused ? GymupColors.accent : GymupColors.border))
                    .frame(height: isFocused ? 2 : 1)
            }
            if showsError {
                Text("루틴 이름을 입력해 주세요")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.critical)
            }
        }
    }
}

struct RoutineEmptyExerciseErrorView: View {
    let onAddExercise: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image("R6IconDumbbell")
                .resizable()
                .frame(width: 32, height: 32)
            Text("운동을 1개 이상 추가해 주세요")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
            Button(action: onAddExercise) {
                Text("운동 추가")
                    .font(GymupTypography.uiMedium)
                    .foregroundStyle(GymupColors.primaryText)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(GymupColors.elevatedSurface, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("routine.editor.add-exercise.error")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: 12).strokeBorder(GymupColors.border, lineWidth: 1))
    }
}

struct RoutineValidationToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image("R6IconInfo")
                .resizable()
                .frame(width: 18, height: 18)
            Text("루틴 이름과 운동을 확인해 주세요")
                .font(GymupTypography.uiMedium)
                .foregroundStyle(GymupColors.primaryText)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
        .accessibilityIdentifier("routine.editor.validation-toast")
    }
}
