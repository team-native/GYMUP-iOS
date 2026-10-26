import SwiftUI

struct HistoryCalendarView: View {

    let onOpenDetail: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var displayedMonth = Date()
    @State private var selectedDate = HistorySampleData.records[0].date

    var body: some View {
        VStack(spacing: 0) {
            HistoryNavigationBar(title: "월간 캘린더", onBack: dismiss.callAsFunction)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    monthCalendar
                    monthlySummary
                    selectedDaySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var monthCalendar: some View {
        HistoryCard {
            VStack(spacing: 18) {
                HStack {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("이전 달")
                    Spacer()
                    Text(HistoryDateText.string(displayedMonth, format: "yyyy년 M월"))
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                    Spacer()
                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("다음 달")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GymupColors.primaryText)
                .buttonStyle(.plain)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { weekday in
                        Text(weekday)
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(Array(calendarCells.enumerated()), id: \.offset) { item in
                        if let date = item.element {
                            calendarDay(date)
                        } else {
                            Color.clear.frame(height: 42)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .padding(.horizontal, -8)
            }
        }
    }

    private func calendarDay(_ date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let hasWorkout = HistorySampleData.records.contains {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 3) {
                Text(date.formatted(.dateTime.day()))
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(isSelected ? .white : GymupColors.primaryText)
                Circle()
                    .fill(hasWorkout ? GymupColors.accent : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isSelected ? GymupColors.accent : .clear, in: Circle())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).month().day()))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var monthlySummary: some View {
        HistoryCard {
            HStack(spacing: 10) {
                HistoryMetricCell(value: "5", unit: "일", title: "운동한 날")
                calendarDivider
                HistoryMetricCell(value: "100", unit: "%", title: "주간 목표")
                calendarDivider
                HistoryMetricCell(value: "7", unit: "주", title: "연속 운동")
            }
        }
    }

    private var calendarDivider: some View {
        Rectangle()
            .fill(GymupColors.separator)
            .frame(width: 1, height: 36)
            .accessibilityHidden(true)
    }

    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HistorySectionTitle(title: HistoryDateText.string(selectedDate, format: "M월 d일 EEEE"))
            if let record = HistorySampleData.records(on: selectedDate).first {
                Button {
                    onOpenDetail(record.id)
                } label: {
                    HistoryWorkoutCalendarCard(record: record)
                }
                .buttonStyle(.plain)
            } else {
                HistoryCard {
                    Text("이 날의 운동 기록이 없어요")
                        .font(GymupTypography.callout)
                        .foregroundStyle(GymupColors.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
                }
            }
        }
    }

    private var calendarCells: [Date?] {
        guard let interval = Calendar.current.dateInterval(of: .month, for: displayedMonth),
              let dayRange = Calendar.current.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let leadingDays = Calendar.current.component(.weekday, from: interval.start) - 1
        let blanks = [Date?](repeating: nil, count: leadingDays)
        let dates = dayRange.compactMap { day in
            Calendar.current.date(byAdding: .day, value: day - 1, to: interval.start)
        }
        return blanks + dates.map(Optional.some)
    }

    private func changeMonth(by amount: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: amount, to: displayedMonth) else { return }
        displayedMonth = newMonth
        if let month = Calendar.current.dateInterval(of: .month, for: newMonth) {
            selectedDate = month.start
        }
    }
}

private struct HistoryWorkoutCalendarCard: View {
    let record: WorkoutRecord

    var body: some View {
        HistoryCard {
            HStack(spacing: 14) {
                HistoryWorkoutPhoto(assetName: record.photoAssetName)
                    .frame(width: 70, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Text(record.routineName)
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                    Text("\(record.durationMinutes)분 · \(record.setCount)세트")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                    Text("\(record.volumeKilograms.formatted()) KG")
                        .font(GymupTypography.metric)
                        .foregroundStyle(GymupColors.primaryText)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GymupColors.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
