import SwiftUI

struct ProfileReminderScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding private var schedule: ProfileReminderSchedule
    @State private var draftSchedule: ProfileReminderSchedule

    init(schedule: Binding<ProfileReminderSchedule>) {
        _schedule = schedule
        _draftSchedule = State(initialValue: schedule.wrappedValue)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: GymupSpacing.large) {
                Text("언제 알려드릴까요?")
                    .font(GymupTypography.headline)
                    .foregroundStyle(GymupColors.primaryText)
                    .accessibilityAddTraits(.isHeader)

                weekdayPicker

                timePicker

                Text(weekdayGuidance)
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("reminder.weekdayGuidance")
            }
            .padding(.horizontal, GymupSpacing.large)
            .padding(.top, GymupSpacing.large)
            .padding(.bottom, GymupSpacing.large)
        }
        .background(GymupColors.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            GymupDetailNavigationBar(title: "리마인더 일정", onBack: { dismiss() })
                .background(GymupColors.canvas)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GymupButton(
                title: "저장",
                font: GymupTypography.uiStrong,
                height: 48,
                cornerRadius: 999,
                action: save
            )
            .accessibilityIdentifier("reminder.save")
            .padding(.horizontal, GymupSpacing.large)
            .padding(.top, GymupSpacing.small)
            .padding(.bottom, GymupSpacing.medium)
            .background(GymupColors.canvas)
        }
    }

    private var weekdayPicker: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(minimum: 44), spacing: GymupSpacing.xSmall),
                        count: 4
                    ),
                    spacing: GymupSpacing.xSmall
                ) {
                    weekdayButtons
                }
            } else {
                HStack(spacing: 2) {
                    weekdayButtons
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center
        )
    }

    private var weekdayButtons: some View {
        ForEach(ProfileReminderSchedule.weekdayOrder, id: \.self) { weekday in
            weekdayButton(weekday)
        }
    }

    private var timePicker: some View {
        DatePicker("리마인더 시간", selection: $draftSchedule.time, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .frame(height: dynamicTypeSize.isAccessibilitySize ? 190 : 150)
            .clipped()
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
            .accessibilityLabel("운동 리마인더 시간")
            .accessibilityIdentifier("reminder.timePicker")
    }

    private var weekdayGuidance: String {
        guard draftSchedule.isEnabled else {
            return "요일을 하나 이상 선택해 주세요. 선택하지 않고 저장하면 일정이 삭제돼요."
        }

        if draftSchedule.weekdays == ProfileReminderSchedule.recommendedWeekdays {
            return "주 3회 목표에 맞춰 월 · 수 · 금을 추천해요."
        }

        if draftSchedule.weekdays.count == 1 {
            return "\(draftSchedule.selectedWeekdaySummary)요일에 리마인더를 받을게요."
        }

        return "\(draftSchedule.selectedWeekdaySummary) 일정으로 리마인더를 받을게요."
    }

    private func weekdayButton(_ weekday: Int) -> some View {
        let isSelected = draftSchedule.weekdays.contains(weekday)
        let title = ProfileReminderSchedule.weekdayNames[weekday, default: ""]

        return Button {
            draftSchedule.toggleWeekday(weekday)
        } label: {
            Text(title)
                .font(GymupTypography.uiStrong)
                .foregroundStyle(isSelected ? .white : GymupColors.secondaryText)
                .frame(width: 32, height: 32)
                .background(isSelected ? GymupColors.accent : GymupColors.elevatedSurface, in: Circle())
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title)요일")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityHint(
            isSelected ? "탭하여 리마인더 일정에서 제외합니다" : "탭하여 리마인더 일정에 추가합니다"
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("reminder.weekday.\(weekday)")
    }

    private func save() {
        schedule = draftSchedule
        dismiss()
    }
}

#Preview("S5 · 리마인더 일정") {
    NavigationStack {
        ProfileReminderScheduleView(schedule: .constant(ProfileReminderSchedule()))
    }
    .preferredColorScheme(.dark)
}

#Preview("일정 없음") {
    NavigationStack {
        ProfileReminderScheduleView(
            schedule: .constant(ProfileReminderSchedule(weekdays: [], time: .now))
        )
    }
    .preferredColorScheme(.dark)
}
