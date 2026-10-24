import SwiftUI

struct ProfileReminderScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var schedule: ProfileReminderSchedule

    private let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                VStack(alignment: .leading, spacing: GymupSpacing.small) {
                    sectionTitle("알림 요일")
                    HStack(spacing: GymupSpacing.small) {
                        ForEach(1...7, id: \.self) { day in
                            weekdayButton(weekdayNames[day - 1], value: day)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(GymupSpacing.medium)
                    .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
                }

                VStack(alignment: .leading, spacing: GymupSpacing.small) {
                    sectionTitle("알림 시간")
                    DatePicker("운동 리마인더 시간", selection: $schedule.time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .clipped()
                        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
                        .accessibilityLabel("운동 리마인더 시간")
                }

                HStack(alignment: .top, spacing: GymupSpacing.small) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(GymupColors.brandText)
                        .accessibilityHidden(true)
                    Text("선택한 요일과 시간은 앱 화면에서만 미리 보여주는 샘플 일정이에요.")
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(GymupSpacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            }
            .padding(.horizontal, GymupSpacing.large)
            .padding(.top, GymupSpacing.large)
            .padding(.bottom, GymupSpacing.xxLarge)
        }
        .background(GymupColors.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            GymupDetailNavigationBar(title: "리마인더 일정", onBack: { dismiss() })
                .background(GymupColors.canvas)
        }
    }

    private func weekdayButton(_ title: String, value: Int) -> some View {
        let isSelected = schedule.weekdays.contains(value)
        return Button {
            if isSelected {
                schedule.weekdays.remove(value)
            } else {
                schedule.weekdays.insert(value)
            }
        } label: {
            Text(title)
                .font(GymupTypography.uiStrong)
                .foregroundStyle(isSelected ? .white : GymupColors.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(isSelected ? GymupColors.accent : GymupColors.elevatedSurface, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title)요일")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(GymupTypography.label)
            .foregroundStyle(GymupColors.secondaryText)
            .frame(minHeight: 20, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    NavigationStack {
        ProfileReminderScheduleView(schedule: .constant(ProfileReminderSchedule()))
            .preferredColorScheme(.dark)
    }
}
