import SwiftUI

struct HistoryCalendarView: View {

    let store: HistoryStore
    let onOpenDetail: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var displayedMonth: Date
    @State private var selectedDate: Date

    @MainActor
    init(store: HistoryStore, onOpenDetail: @escaping (UUID) -> Void) {
        self.store = store
        self.onOpenDetail = onOpenDetail
        let initialDate = store.records.first?.date ?? .now
        let initialMonth = Calendar.current.dateInterval(of: .month, for: initialDate)?.start ?? initialDate
        _displayedMonth = State(initialValue: initialMonth)
        _selectedDate = State(initialValue: initialDate)
    }

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
                    .accessibilityIdentifier("history.calendar.previousMonth")
                    Spacer()
                    Text(HistoryDateText.string(displayedMonth, format: "yyyy년 M월"))
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                        .accessibilityIdentifier("history.calendar.month")
                    Spacer()
                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("다음 달")
                    .accessibilityIdentifier("history.calendar.nextMonth")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GymupColors.primaryText)
                .buttonStyle(.plain)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                    ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { weekday in
                        Text(weekday)
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .accessibilityHidden(true)
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
        let calendar = Calendar.current
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let workouts = store.records(on: date)
        let hasWorkout = !workouts.isEmpty
        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 3) {
                Text(date.formatted(.dateTime.day()))
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(isSelected ? .white : GymupColors.primaryText)
                Circle()
                    .fill(hasWorkout ? (isSelected ? .white : GymupColors.accent) : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(isSelected ? GymupColors.accent : .clear, in: Circle())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(calendarDayAccessibilityLabel(date, workoutCount: workouts.count))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("history.calendar.date.\(HistoryDateText.string(date, format: "yyyy-MM-dd"))")
    }

    private var monthlySummary: some View {
        let summary = HistoryCalendarSummary(records: monthRecords)
        HistoryCard {
            HStack(spacing: 10) {
                HistoryMetricCell(value: "\(summary.workoutDays)", unit: "일", title: "운동한 날")
                calendarDivider
                // 주간 목표와 연속 운동은 데이터 모델 연결 전까지 Figma 시안 값을 유지합니다.
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
            HistorySectionTitle(
                title: HistoryDateText.string(selectedDate, format: "M월 d일 EEEE"),
                subtitle: selectedDayRecords.isEmpty ? "운동 기록 없음" : "\(selectedDayRecords.count)회 운동"
            )
            if selectedDayRecords.isEmpty {
                HistoryCard {
                    Text("이 날의 운동 기록이 없어요")
                        .font(GymupTypography.callout)
                        .foregroundStyle(GymupColors.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
                }
            } else {
                ForEach(selectedDayRecords) { record in
                    Button {
                        onOpenDetail(record.id)
                    } label: {
                        HistoryWorkoutCalendarCard(record: record)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("history.calendar.record.\(record.id.uuidString)")
                }
            }
        }
    }

    private var monthRecords: [WorkoutRecord] {
        store.records(inMonthOf: displayedMonth)
    }

    private var selectedDayRecords: [WorkoutRecord] {
        store.records(on: selectedDate)
    }

    private var calendarCells: [Date?] {
        guard let interval = Calendar.current.dateInterval(of: .month, for: displayedMonth),
              let dayRange = Calendar.current.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let leadingDays = Calendar.current.component(.weekday, from: interval.start) - 1
        let blanks = [Date?](repeating: nil, count: leadingDays)
        let dates = dayRange.compactMap { day in
            Calendar.current.date(byAdding: .day, value: day - 1, to: interval.start)
        }
        let cells = blanks + dates.map(Optional.some)
        let trailingDays = (7 - cells.count % 7) % 7
        return cells + [Date?](repeating: nil, count: trailingDays)
    }

    private func changeMonth(by amount: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: amount, to: displayedMonth) else { return }
        displayedMonth = newMonth
        let newMonthRecords = store.records(inMonthOf: newMonth)
        selectedDate = newMonthRecords.first?.date
            ?? Calendar.current.dateInterval(of: .month, for: newMonth)?.start
            ?? newMonth
    }

    private func calendarDayAccessibilityLabel(_ date: Date, workoutCount: Int) -> String {
        let dateText = date.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).month().day().weekday(.wide))
        return workoutCount == 0 ? "\(dateText), 운동 기록 없음" : "\(dateText), 운동 \(workoutCount)회"
    }
}

struct HistoryCalendarSummary: Equatable {
    let workoutDays: Int

    init(records: [WorkoutRecord], calendar: Calendar = .current) {
        workoutDays = Set(records.map { calendar.startOfDay(for: $0.date) }).count
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

#Preview("G4 월간 캘린더") {
    NavigationStack {
        HistoryCalendarView(store: HistoryStore(records: HistoryListSampleData.records), onOpenDetail: { _ in })
    }
    .preferredColorScheme(.dark)
}
