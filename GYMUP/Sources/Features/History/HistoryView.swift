import SwiftUI

struct HistoryView: View {
    let onOpenRoutines: () -> Void
    @State private var path: [HistoryRoute] = []
    @State private var selectedDate = HistorySampleData.records[0].date

    init(onOpenRoutines: @escaping () -> Void = {}) {
        self.onOpenRoutines = onOpenRoutines
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
    }

    private var historyList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                weekSelector
                weeklySummary
                if selectedRecords.isEmpty {
                    HistoryEmptyContent(onOpenRoutines: onOpenRoutines)
                } else {
                    workoutSection
                }
                growthLink
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(GymupColors.canvas.ignoresSafeArea())
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("기록")
                .font(GymupTypography.homeTitle)
                .tracking(-0.43)
                .foregroundStyle(GymupColors.primaryText)
            Spacer()
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
        .frame(height: 48)
    }

    private var weekSelector: some View {
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let hasWorkout = HistorySampleData.records.contains {
                    Calendar.current.isDate($0.date, inSameDayAs: date)
                }
                Button {
                    selectedDate = date
                } label: {
                    VStack(spacing: 8) {
                        Text(date.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).weekday(.narrow)))
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(isSelected ? GymupColors.accent : GymupColors.secondaryText)
                        Text(date.formatted(.dateTime.day()))
                            .font(GymupTypography.uiStrong)
                            .foregroundStyle(isSelected ? .white : GymupColors.primaryText)
                            .frame(width: 36, height: 36)
                            .background(isSelected ? GymupColors.accent : .clear, in: Circle())
                        Circle()
                            .fill(hasWorkout ? GymupColors.accent : .clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(date.formatted(.dateTime.locale(Locale(identifier: "ko_KR")).month().day().weekday(.wide)))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("주간 날짜 선택")
    }

    private var weeklySummary: some View {
        HistoryCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 6) {
                    Text("이번 달")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(GymupColors.secondaryText)
                }
                HStack(spacing: 8) {
                    HistoryMetricCell(value: "9", unit: "회", title: "운동 횟수")
                    metricDivider
                    HistoryMetricCell(value: "8H 12M", unit: "", title: "운동 시간")
                    metricDivider
                    HistoryMetricCell(value: "72.4", unit: "T", title: "총 볼륨")
                }
            }
        }
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(GymupColors.separator)
            .frame(width: 1, height: 36)
            .accessibilityHidden(true)
    }

    private var workoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HistorySectionTitle(title: "운동 기록", subtitle: "\(selectedRecords.count)회")
            ForEach(selectedRecords) { record in
                Button {
                    path.append(.detail(record.id))
                } label: {
                    HistoryWorkoutRow(record: record)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("history.record.\(record.id.uuidString)")
            }
        }
    }

    private var growthLink: some View {
        Button {
            path.append(.growth)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GymupColors.accent)
                    .frame(width: 40, height: 40)
                    .background(GymupColors.accent.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("성장 그래프")
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                    Text("운동 기록으로 변화를 확인해요")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GymupColors.secondaryText)
            }
            .padding(14)
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("history.openGrowth")
    }

    private var selectedRecords: [WorkoutRecord] {
        HistorySampleData.records(on: selectedDate)
    }

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let start = calendar.date(byAdding: .day, value: 1 - weekday, to: selectedDate) ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    @ViewBuilder
    private func destination(for route: HistoryRoute) -> some View {
        switch route {
        case let .detail(id):
            if let record = HistorySampleData.record(with: id) {
                HistoryDetailView(record: record, onOpenAlbum: { path.append(.album) })
            }
        case .calendar:
            HistoryCalendarView(onOpenDetail: { path.append(.detail($0)) })
        case .growth:
            HistoryGrowthView()
        case .album:
            HistoryAlbumView(onCompare: { path.append(.comparison($0)) })
        case let .comparison(assetName):
            HistoryComparisonView(assetName: assetName)
        }
    }
}

private struct HistoryWorkoutRow: View {
    let record: WorkoutRecord

    var body: some View {
        HistoryCard {
            HStack(spacing: 14) {
                HistoryWorkoutPhoto(assetName: record.photoAssetName)
                    .frame(width: 76, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(HistoryDateText.string(record.date, format: "M월 d일 EEEE"))
                                .font(GymupTypography.uiCaption)
                                .foregroundStyle(GymupColors.secondaryText)
                            Text(record.routineName)
                                .font(GymupTypography.uiStrong)
                                .foregroundStyle(GymupColors.primaryText)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    Text(record.category)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .lineLimit(1)
                    HStack(spacing: 10) {
                        Label("\(record.durationMinutes)분", systemImage: "clock")
                        Label("\(record.setCount)세트", systemImage: "dumbbell")
                        if record.growth > 0 {
                            Text("+\(record.growth) Growth")
                                .foregroundStyle(Color(red: 1, green: 0.43, blue: 0.45))
                        }
                    }
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(record.accessibilityDescription)
    }
}

private struct HistoryEmptyContent: View {
    let onOpenRoutines: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image("H2EquipmentEmpty")
                .resizable()
                .scaledToFit()
                .frame(width: 148, height: 88)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("아직 운동 기록이 없어요")
                    .font(GymupTypography.headline)
                    .foregroundStyle(GymupColors.primaryText)
                Text("운동을 완료하면 이곳에서\n기록과 성장을 확인할 수 있어요.")
                    .font(GymupTypography.callout)
                    .foregroundStyle(GymupColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: onOpenRoutines) {
                Text("루틴 시작하기")
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(GymupColors.accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("history.startRoutine")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 28)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    HistoryView()
        .preferredColorScheme(.dark)
}
