import SwiftUI

struct HistoryDetailView: View {
    let record: WorkoutRecord
    let onOpenAlbum: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isShowingAllExercises = false

    var body: some View {
        VStack(spacing: 0) {
            HistoryNavigationBar(title: "운동 상세", onBack: dismiss.callAsFunction)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    workoutHeading
                    metrics
                    photoBanner
                    exerciseList
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var workoutHeading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(HistoryDateText.string(record.date, format: "yyyy년 M월 d일 EEEE"))
                .font(HistoryDetailTypography.caption).foregroundStyle(GymupColors.secondaryText)
            Text(record.routineName).font(GymupTypography.title).foregroundStyle(GymupColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text(record.category).font(GymupTypography.callout).foregroundStyle(GymupColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metrics: some View {
        HistoryCard {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 0) {
                    accessibilityMetricRow(title: "운동 시간", value: "\(record.durationMinutes)", unit: "분")
                    horizontalMetricDivider
                    accessibilityMetricRow(title: "총 세트", value: "\(record.setCount)", unit: "세트")
                    horizontalMetricDivider
                    accessibilityMetricRow(title: "총 볼륨", value: record.volumeKilograms.formatted(), unit: "KG")
                }
            } else {
                HStack(spacing: 10) {
                    HistoryMetricCell(value: "\(record.durationMinutes)", unit: "분", title: "운동 시간")
                    metricDivider
                    HistoryMetricCell(value: "\(record.setCount)", unit: "세트", title: "총 세트")
                    metricDivider
                    HistoryMetricCell(value: record.volumeKilograms.formatted(), unit: "KG", title: "총 볼륨")
                }
            }
        }
    }

    private func accessibilityMetricRow(title: String, value: String, unit: String) -> some View {
        HStack(spacing: 8) {
            Text(title).font(HistoryDetailTypography.caption).foregroundStyle(GymupColors.secondaryText)
            Spacer(minLength: 8)
            Text(value).font(HistoryDetailTypography.metric).foregroundStyle(GymupColors.primaryText).lineLimit(1).minimumScaleFactor(0.7)
            Text(unit).font(HistoryDetailTypography.caption).foregroundStyle(GymupColors.secondaryText)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
    }

    private var horizontalMetricDivider: some View {
        Rectangle().fill(GymupColors.separator).frame(height: 1).accessibilityHidden(true)
    }

    private var metricDivider: some View {
        Rectangle().fill(GymupColors.separator).frame(width: 1, height: 36).accessibilityHidden(true)
    }

    private var photoBanner: some View {
        Button(action: onOpenAlbum) {
            ZStack(alignment: .leading) {
                HistoryWorkoutPhoto(assetName: record.photoAssetName)
                    .frame(height: 112)
                    .overlay {
                        LinearGradient(
                            colors: [.black.opacity(0.75), .black.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                VStack(alignment: .leading, spacing: 6) {
                    Text("오운완 사진 1장").font(GymupTypography.uiStrong).foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Text("Progress Album에서 보기").font(GymupTypography.uiCaption)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.78))
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("오운완 사진 한 장, Progress Album에서 보기")
        .accessibilityIdentifier("history.openAlbum")
    }

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HistorySectionTitle(title: "운동 상세", subtitle: "\(record.exercises.count)종목")
            ForEach(displayedExercises) { HistoryExerciseCard(exercise: $0) }
            if record.exercises.count > 2 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingAllExercises.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(isShowingAllExercises ? "접기" : "운동 종목 더 보기")
                        Image(systemName: isShowingAllExercises ? "chevron.up" : "chevron.down")
                    }
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var displayedExercises: [WorkoutExerciseRecord] {
        isShowingAllExercises ? record.exercises : Array(record.exercises.prefix(2))
    }
}

private struct HistoryExerciseCard: View {
    let exercise: WorkoutExerciseRecord
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HistoryCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(exercise.name).font(HistoryDetailTypography.body).foregroundStyle(GymupColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true).layoutPriority(1)
                    Spacer(minLength: 0)
                    Text("\(exercise.sets.count)세트").font(HistoryDetailTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                VStack(spacing: 10) {
                    ForEach(exercise.sets) { set in
                        Group {
                            if dynamicTypeSize.isAccessibilitySize {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("\(set.id)세트")
                                        Spacer(minLength: 8)
                                        if set.isPersonalRecord { personalRecordBadge }
                                    }
                                    HStack {
                                        Text("\(set.weight.formatted()) kg")
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 8)
                                        Text("\(set.repetitions)회")
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            } else {
                                HStack {
                                    Text("\(set.id)세트")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("\(set.weight.formatted()) kg")
                                        .lineLimit(1).minimumScaleFactor(0.75)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    Text("\(set.repetitions)회")
                                        .lineLimit(1).minimumScaleFactor(0.75)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    if set.isPersonalRecord { personalRecordBadge }
                                }
                            }
                        }
                        .font(HistoryDetailTypography.caption)
                        .foregroundStyle(set.isPersonalRecord ? GymupColors.primaryText : GymupColors.secondaryText)
                        .accessibilityElement(children: .combine).accessibilityLabel(set.accessibilityDescription)
                    }
                }
            }
        }
    }

    private var personalRecordBadge: some View {
        Text("PR").font(HistoryDetailTypography.badge).foregroundStyle(.white)
            .padding(.horizontal, 7).padding(.vertical, 4).background(GymupColors.accent, in: Capsule()).fixedSize()
    }
}

private enum HistoryDetailTypography {
    static let caption = Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption)
    static let body = Font.custom("GothicA1-SemiBold", size: 14, relativeTo: .subheadline)
    static let metric = Font.custom("BarlowCondensed-ExtraBold", size: 18, relativeTo: .title3)
    static let badge = Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption)
}

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
