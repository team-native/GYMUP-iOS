import SwiftUI

struct HistoryWeekSelector: View {
    let dates: [Date]
    let selectedDate: Date
    let workoutDates: [Date]
    let onSelect: (Date) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let hasWorkout = workoutDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
                Button {
                    onSelect(date)
                } label: {
                    VStack(spacing: 4) {
                        VStack(spacing: 2) {
                            Text(date.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).weekday(.narrow)))
                                .font(GymupTypography.uiCaption)
                                .foregroundStyle(isSelected ? .white : GymupColors.secondaryText)
                            Text(date.formatted(.dateTime.day()))
                                .font(GymupTypography.uiStrong)
                                .foregroundStyle(GymupColors.primaryText)
                        }
                        .frame(width: 36, height: 40)
                        .background(
                            isSelected ? GymupColors.accent : .clear,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        Circle()
                            .fill(hasWorkout ? GymupColors.accent : .clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel(for: date, hasWorkout: hasWorkout))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("history.date.\(HistoryDateText.string(date, format: "yyyy-MM-dd"))")
            }
        }
        .padding(.horizontal, 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("주간 날짜 선택")
    }

    private func accessibilityLabel(for date: Date, hasWorkout: Bool) -> String {
        let day = date.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).month().day().weekday(.wide))
        return hasWorkout ? "\(day), 운동 기록 있음" : day
    }
}

struct HistoryMonthlySummary: View {
    let count: Int
    let selectedMonth: Date
    let duration: String
    let volume: String
    let monthOptions: [Date]
    let onSelectMonth: (Date) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(monthOptions, id: \.self) { month in
                    Button(HistoryDateText.string(month, format: "M월")) {
                        onSelectMonth(month)
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(count)")
                            .font(GymupTypography.metric)
                            .foregroundStyle(GymupColors.primaryText)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                        Text("회")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    Text("\(HistoryDateText.string(selectedMonth, format: "M월")) 운동")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .accessibilityLabel(
                "기록 월 선택, \(count)회, \(HistoryDateText.string(selectedMonth, format: "M월")) 운동"
            )
            .accessibilityIdentifier("history.selectMonth")

            metricDivider
            HistoryMetricCell(value: duration, unit: "", title: "총 시간")
            metricDivider
            HistoryMetricCell(value: volume, unit: "T", title: "총 볼륨")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(GymupColors.separator)
            .frame(width: 1, height: 36)
            .accessibilityHidden(true)
    }
}

struct HistoryServerErrorNotice: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(message)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Button("다시 시도", action: onRetry)
                .font(GymupTypography.uiStrong)
                .foregroundStyle(GymupColors.accent)
                .frame(minHeight: 44)
                .accessibilityIdentifier("history.server.retry")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct HistoryWorkoutRow: View {
    let record: HistoryListEntry
    let isServerSummary: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text(record.date.formatted(.dateTime.day()))
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                Text(record.date.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).weekday(.narrow)))
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            .frame(width: 36, height: 36)
            .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(record.routineName)
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                        .lineLimit(1)
                    if let personalRecordCount = record.personalRecordCount, personalRecordCount > 0 {
                        Text("PR \(personalRecordCount)")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(GymupColors.accent.opacity(0.12), in: Capsule())
                    }
                    if isServerSummary {
                        Text("서버 기록")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    Spacer(minLength: 0)
                    if !isServerSummary {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(GymupColors.secondaryText)
                            .accessibilityHidden(true)
                    }
                }
                Text("\(record.durationMinutes)분 · \(record.setCount)세트 · \(record.volumeKilograms.formatted())kg")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(record.accessibilityDescription)
    }
}
