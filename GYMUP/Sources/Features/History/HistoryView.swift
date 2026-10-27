import SwiftUI

struct HistoryView: View {
    let store: HistoryStore
    let onOpenRoutines: () -> Void
    let onComparisonPresented: (Bool) -> Void
    @State private var path: [HistoryRoute] = []
    @State private var selectedMonth: Date
    @State private var selectedDate: Date
    @State private var visibleWorkoutID: UUID?

    @MainActor
    init(
        store: HistoryStore,
        onOpenRoutines: @escaping () -> Void = {},
        onComparisonPresented: @escaping (Bool) -> Void = { _ in }
    ) {
        self.store = store
        self.onOpenRoutines = onOpenRoutines
        self.onComparisonPresented = onComparisonPresented
        let initialRecord = store.records.first
        let initialDate = initialRecord?.date ?? .now
        let initialMonth = Calendar.current.dateInterval(of: .month, for: initialDate)?.start ?? initialDate
        _selectedMonth = State(initialValue: initialMonth)
        _selectedDate = State(initialValue: initialDate)
        _visibleWorkoutID = State(initialValue: initialRecord?.id)
    }

    var body: some View {
        NavigationStack(path: $path) {
            historyList
                .navigationDestination(for: HistoryRoute.self) { route in
                    destination(for: route)
                }
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(GymupColors.canvas.ignoresSafeArea())
        .onAppear {
            onComparisonPresented(isComparisonPresented)
        }
        .onChange(of: path) { _, _ in
            onComparisonPresented(isComparisonPresented)
        }
    }

    private var historyList: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if store.records.isEmpty {
                        emptyHistoryContent
                            .frame(minHeight: max(geometry.size.height - 36, 0))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 28)
                    } else {
                        populatedHistoryContent(using: proxy)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 28)
                    }
                }
                .scrollPosition(id: $visibleWorkoutID, anchor: .top)
                .background(GymupColors.canvas.ignoresSafeArea())
                .onChange(of: store.records.map(\.id)) { _, _ in
                    guard let latestRecord = store.records.first else { return }
                    selectedMonth = Calendar.current.dateInterval(of: .month, for: latestRecord.date)?.start
                        ?? latestRecord.date
                    selectedDate = latestRecord.date
                    visibleWorkoutID = latestRecord.id
                }
            }
        }
    }

    private var emptyHistoryContent: some View {
        VStack(spacing: 0) {
            header(showsCalendarButton: false)
            Spacer(minLength: 24)
            HistoryEmptyContent(onOpenRoutines: onOpenRoutines)
            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity)
    }

    private func populatedHistoryContent(using proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            header(showsCalendarButton: true)
            weekSelector(using: proxy)
            monthlySummary
            if !monthRecords.isEmpty {
                workoutSection
            }
            growthLink
        }
    }

    private func weekSelector(using proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let hasWorkout = monthRecords.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
                Button {
                    select(date, using: proxy)
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

    private var monthlySummary: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(monthOptions, id: \.self) { month in
                    Button(HistoryDateText.string(month, format: "M월")) {
                        selectMonth(month)
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(monthRecords.count)")
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
                "기록 월 선택, \(monthRecords.count)회, \(HistoryDateText.string(selectedMonth, format: "M월")) 운동"
            )
            .accessibilityIdentifier("history.selectMonth")

            metricDivider
            HistoryMetricCell(value: formattedDuration, unit: "", title: "총 시간")
            metricDivider
            HistoryMetricCell(value: formattedVolume, unit: "T", title: "총 볼륨")
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

    private var workoutSection: some View {
        VStack(spacing: 8) {
            ForEach(monthRecords) { record in
                Button {
                    path.append(.detail(record.id))
                } label: {
                    HistoryWorkoutRow(record: record)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("history.record.\(record.id.uuidString)")
                .id(record.id)
            }
        }
        .scrollTargetLayout()
    }

    private var growthLink: some View {
        Button {
            path.append(.growth)
        } label: {
            Text("기록이 있을 때 화면 보기")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.accent)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("history.openGrowth")
    }

    private var monthRecords: [WorkoutRecord] {
        store.records(inMonthOf: selectedMonth)
    }

    private var formattedDuration: String {
        let totalMinutes = monthRecords.reduce(0) { $0 + $1.durationMinutes }
        return "\(totalMinutes / 60)H \(totalMinutes % 60)M"
    }

    private var formattedVolume: String {
        let totalKilograms = monthRecords.reduce(0) { $0 + $1.volumeKilograms }
        return String(format: "%.1f", Double(totalKilograms) / 1_000)
    }

    private func select(_ date: Date, using proxy: ScrollViewProxy) {
        selectedDate = date
        guard let record = monthRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            visibleWorkoutID = record.id
            proxy.scrollTo(record.id, anchor: .top)
        }
    }

    private func selectMonth(_ month: Date) {
        selectedMonth = month
        let monthRecords = store.records(inMonthOf: month)
        selectedDate = monthRecords.first?.date ?? month
        visibleWorkoutID = monthRecords.first?.id
    }

    @ViewBuilder
    private func destination(for route: HistoryRoute) -> some View {
        switch route {
        case let .detail(id):
            if let record = store.record(with: id)
                ?? HistoryListSampleData.record(with: id)
                ?? HistorySampleData.record(with: id) {
                HistoryDetailView(record: record, onOpenAlbum: { path.append(.album) })
            }
        case .calendar:
            HistoryCalendarView(store: store, onOpenDetail: { path.append(.detail($0)) })
        case .growth:
            HistoryGrowthView()
        case .album:
            HistoryAlbumView(
                store: store,
                onOpenRoutines: onOpenRoutines,
                onOpenDetail: { path.append(.detail($0)) },
                onCompare: { path.append(.comparison($0)) }
            )
        case let .comparison(recordID):
            HistoryComparisonView(store: store, initialRecordID: recordID)
        }
    }
}

private extension HistoryView {
    var isComparisonPresented: Bool {
        guard let route = path.last else { return false }
        if case .comparison = route { return true }
        return false
    }
}

private extension HistoryView {
    var monthOptions: [Date] {
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        return [selectedMonth, previousMonth]
    }

    var weekDates: [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysFromMonday = (weekday + 5) % 7
        let start = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate) ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    func header(showsCalendarButton: Bool) -> some View {
        HStack(alignment: .center) {
            Text("기록")
                .font(GymupTypography.homeTitle)
                .tracking(-0.43)
                .foregroundStyle(GymupColors.primaryText)
            Spacer()
            if showsCalendarButton {
                Button {
                    path.append(.calendar)
                } label: {
                    Image("H1IconCalendar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("월간 캘린더")
                .accessibilityIdentifier("history.openCalendar")
            }
        }
        .frame(height: 48)
    }

    func accessibilityLabel(for date: Date, hasWorkout: Bool) -> String {
        let day = date.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).month().day().weekday(.wide))
        return hasWorkout ? "\(day), 운동 기록 있음" : day
    }
}

private struct HistoryWorkoutRow: View {
    let record: WorkoutRecord

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
                    if record.growth > 0 {
                        Text("PR \(record.growth)")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(GymupColors.accent.opacity(0.12), in: Capsule())
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(GymupColors.secondaryText)
                        .accessibilityHidden(true)
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

#Preview {
    HistoryView(store: HistoryStore())
        .preferredColorScheme(.dark)
}

#Preview("G1 기록 목록") {
    HistoryView(store: HistoryStore(records: HistoryListSampleData.records))
        .preferredColorScheme(.dark)
}
