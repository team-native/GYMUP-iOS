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
            VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                Text("언제 알려드릴까요?")
                    .font(.custom("GothicA1-ExtraBold", size: 20, relativeTo: .headline))
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
            .padding(.horizontal, 20)
            .padding(.top, 8)
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
                height: 50,
                cornerRadius: 999,
                action: save
            )
            .accessibilityIdentifier("reminder.save")
            .padding(.horizontal, 36)
            .padding(.top, GymupSpacing.small)
            .padding(.bottom, 0)
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
        HStack(spacing: 0) {
            ReminderWheel(title: "시", values: Array(1...12), selection: hourSelection,
                          text: { String($0) }, identifier: "reminder.hourPicker")
            ReminderWheel(title: "분", values: Array(stride(from: 0, through: 55, by: 5)), selection: minuteSelection,
                          text: { String(format: "%02d", $0) }, identifier: "reminder.minutePicker")
            ReminderWheel(title: "오전/오후", values: ReminderPeriod.allCases, selection: periodSelection,
                          text: { $0.rawValue }, isPeriod: true, identifier: "reminder.periodPicker")
        }
        .frame(maxWidth: .infinity)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var hourSelection: Binding<Int> {
        Binding(
            get: {
                let hour = Calendar.current.component(.hour, from: draftSchedule.time)
                return hour % 12 == 0 ? 12 : hour % 12
            },
            set: { updateTime(hour: $0) }
        )
    }

    private var minuteSelection: Binding<Int> {
        Binding(
            get: { Calendar.current.component(.minute, from: draftSchedule.time) / 5 * 5 },
            set: { updateTime(minute: $0) }
        )
    }

    private var periodSelection: Binding<ReminderPeriod> {
        Binding(
            get: { Calendar.current.component(.hour, from: draftSchedule.time) < 12 ? .morning : .afternoon },
            set: { updateTime(period: $0) }
        )
    }

    private var weekdayGuidance: String {
        guard draftSchedule.isEnabled else {
            return "요일을 하나 이상 선택해 주세요. 선택하지 않고 저장하면 일정이 삭제돼요."
        }

        if draftSchedule.weekdays == ProfileReminderSchedule.recommendedWeekdays {
            return "주 3회 목표에 맞춰 월 · 수 · 금을 추천했어요."
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
                .frame(width: 36, height: 36)
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

    private func updateTime(hour: Int? = nil, minute: Int? = nil, period: ReminderPeriod? = nil) {
        let currentHour = Calendar.current.component(.hour, from: draftSchedule.time)
        let currentMinute = Calendar.current.component(.minute, from: draftSchedule.time)
        let hour12 = hour ?? (currentHour % 12 == 0 ? 12 : currentHour % 12)
        let currentPeriod: ReminderPeriod = currentHour < 12 ? .morning : .afternoon
        let selectedPeriod = period ?? currentPeriod
        var components = Calendar.current.dateComponents([.year, .month, .day], from: draftSchedule.time)
        components.hour = hour12 % 12 + (selectedPeriod == .afternoon ? 12 : 0)
        components.minute = minute ?? (currentMinute / 5 * 5)
        components.second = 0

        if let updatedTime = Calendar.current.date(from: components) {
            draftSchedule.time = updatedTime
        }
    }
}

private enum ReminderPeriod: String, CaseIterable, Identifiable {
    case morning = "오전"
    case afternoon = "오후"

    var id: Self { self }
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
