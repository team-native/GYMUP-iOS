import Foundation
import Observation
import SwiftUI

struct HistoryServerWorkoutSetDetail: Equatable, Identifiable {
    let index: Int
    let weight: Double
    let reps: Int
    let isPersonalRecord: Bool

    var id: Int { index }

    var accessibilityDescription: String {
        let personalRecord = isPersonalRecord ? ", 개인 기록" : ""
        return "\(index)세트, \(weight.formatted())킬로그램, \(reps)회\(personalRecord)"
    }
}

struct HistoryServerExerciseDetail: Equatable, Identifiable {
    let ordinal: Int
    let sets: [HistoryServerWorkoutSetDetail]

    var id: Int { ordinal }
}

struct HistoryServerWorkoutDetail: Equatable {
    let durationMinutes: Int
    let totalSets: Int
    let volumeKilograms: Int
    let exercises: [HistoryServerExerciseDetail]

    init?(workout: HistoryServerWorkout, response: WorkoutDetailResponse) {
        guard response.workoutId == workout.id,
              response.duration >= 0,
              response.totalSets >= 0,
              response.volume.isFinite,
              response.volume >= 0,
              response.volume < Double(Int.max),
              response.exercises.allSatisfy({ exercise in
                  exercise.sets.allSatisfy { $0.reps >= 0 && $0.weight.isFinite && $0.weight >= 0 }
              })
        else {
            return nil
        }

        durationMinutes = Int(ceil(Double(response.duration) / 60))
        totalSets = response.totalSets
        volumeKilograms = Int(response.volume.rounded())
        exercises = response.exercises.enumerated().map { exerciseIndex, exercise in
            HistoryServerExerciseDetail(
                ordinal: exerciseIndex + 1,
                sets: exercise.sets.enumerated().map { setIndex, set in
                    HistoryServerWorkoutSetDetail(
                        index: setIndex + 1,
                        weight: set.weight,
                        reps: set.reps,
                        isPersonalRecord: set.isPersonalRecord
                    )
                }
            )
        }
    }
}

@Observable
@MainActor
final class HistoryServerWorkoutDetailViewModel {
    let workout: HistoryServerWorkout
    private let service: WorkoutDetailReading?

    private(set) var detail: HistoryServerWorkoutDetail?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(workout: HistoryServerWorkout, service: WorkoutDetailReading?) {
        self.workout = workout
        self.service = service
    }

    func load() async {
        guard !isLoading, detail == nil else { return }
        await fetch()
    }

    func retry() async {
        guard !isLoading else { return }
        await fetch()
    }

    private func fetch() async {
        guard let service else {
            errorMessage = "서버 기록을 불러올 수 없어요. 잠시 후 다시 시도해 주세요."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await service.detail(workoutId: workout.id)
            guard let mappedDetail = HistoryServerWorkoutDetail(workout: workout, response: response) else {
                throw APIClientError.invalidResponse
            }
            detail = mappedDetail
            errorMessage = nil
        } catch {
            if let apiError = error as? APIClientError,
               case let .server(_, detail) = apiError {
                errorMessage = detail.message
            } else {
                errorMessage = "서버 기록을 불러오지 못했어요. 다시 시도해 주세요."
            }
        }
    }
}

struct HistoryServerWorkoutDetailScreen: View {
    let workout: HistoryServerWorkout
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: HistoryServerWorkoutDetailViewModel

    init(workout: HistoryServerWorkout, service: WorkoutDetailReading?) {
        self.workout = workout
        _viewModel = State(initialValue: HistoryServerWorkoutDetailViewModel(workout: workout, service: service))
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if let detail = viewModel.detail {
                        metrics(detail)
                        exerciseList(detail)
                    } else if let errorMessage = viewModel.errorMessage {
                        errorNotice(errorMessage)
                    } else {
                        ProgressView()
                            .tint(GymupColors.accent)
                            .frame(maxWidth: .infinity, minHeight: 180)
                            .accessibilityLabel("운동 상세 기록 불러오는 중")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .accessibilityIdentifier("history.serverDetail.screen")
    }

    @ViewBuilder
    private var navigationBar: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                backButton
                title
                    .font(GymupTypography.uiStrong)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        } else {
            HStack(spacing: 4) {
                backButton
                Spacer(minLength: 0)
                title
                    .font(GymupTypography.uiStrong)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                Spacer(minLength: 0)
                Color.clear
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 52)
        }
    }

    private var backButton: some View {
        Button(action: dismiss.callAsFunction) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(GymupColors.primaryText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("뒤로")
        .accessibilityIdentifier("history.serverDetail.back")
    }

    private var title: some View {
        Text("\(HistoryDateText.string(workout.date, format: "M월 d일")) · \(workout.routineName)")
            .foregroundStyle(GymupColors.primaryText)
            .accessibilityIdentifier("history.serverDetail.title")
    }

    private func metrics(_ detail: HistoryServerWorkoutDetail) -> some View {
        HistoryCard {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 0) {
                    accessibilityMetricRow(title: "시간", value: "\(detail.durationMinutes)", unit: "분")
                    horizontalMetricDivider
                    accessibilityMetricRow(title: "총 세트", value: "\(detail.totalSets)", unit: "세트")
                    horizontalMetricDivider
                    accessibilityMetricRow(title: "총 볼륨", value: detail.volumeKilograms.formatted(), unit: "KG")
                }
            } else {
                HStack(spacing: 10) {
                    HistoryMetricCell(value: "\(detail.durationMinutes)", unit: "분", title: "시간")
                    metricDivider
                    HistoryMetricCell(value: "\(detail.totalSets)", unit: "세트", title: "총 세트")
                    metricDivider
                    HistoryMetricCell(value: detail.volumeKilograms.formatted(), unit: "KG", title: "총 볼륨")
                }
            }
        }
        .accessibilityIdentifier("history.serverDetail.metrics")
    }

    private func accessibilityMetricRow(title: String, value: String, unit: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
            Spacer(minLength: 8)
            Text(value)
                .font(GymupTypography.metric)
                .foregroundStyle(GymupColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(unit)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(GymupColors.separator)
            .frame(width: 1, height: 36)
            .accessibilityHidden(true)
    }

    private var horizontalMetricDivider: some View {
        Rectangle()
            .fill(GymupColors.separator)
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private func exerciseList(_ detail: HistoryServerWorkoutDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HistorySectionTitle(title: "운동 상세", subtitle: "\(detail.exercises.count)종목")
            ForEach(detail.exercises) { exercise in
                exerciseCard(exercise)
            }
        }
        .accessibilityIdentifier("history.serverDetail.exercises")
    }

    private func exerciseCard(_ exercise: HistoryServerExerciseDetail) -> some View {
        HistoryCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("종목 \(exercise.ordinal)")
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                    Spacer(minLength: 0)
                    Text("\(exercise.sets.count)세트")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                }

                if exercise.sets.isEmpty {
                    Text("세트 기록 없음")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 10))
                } else {
                    VStack(spacing: 10) {
                        ForEach(exercise.sets) { set in
                            setRow(set, exerciseOrdinal: exercise.ordinal)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("history.serverDetail.exercise.\(exercise.ordinal)")
    }

    private func setRow(_ set: HistoryServerWorkoutSetDetail, exerciseOrdinal: Int) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(set.index)세트")
                    setDescription(set)
                }
            } else {
                HStack(spacing: 8) {
                    Text("\(set.index)세트")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    setDescription(set)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .font(GymupTypography.uiCaption)
        .foregroundStyle(set.isPersonalRecord ? GymupColors.primaryText : GymupColors.secondaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            set.isPersonalRecord ? GymupColors.accent.opacity(0.16) : GymupColors.elevatedSurface,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay {
            if set.isPersonalRecord {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(GymupColors.accent.opacity(0.32), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(set.accessibilityDescription)
        .accessibilityIdentifier("history.serverDetail.exercise.\(exerciseOrdinal).set.\(set.index)")
    }

    private func setDescription(_ set: HistoryServerWorkoutSetDetail) -> some View {
        HStack(spacing: 4) {
            Text("\(set.weight.formatted()) kg")
            Text("×")
            Text("\(set.reps)회")
            if set.isPersonalRecord {
                Text("PR")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(GymupColors.accent, in: Capsule())
            }
        }
        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
        .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.75)
    }

    private func errorNotice(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button("다시 시도") {
                Task { await viewModel.retry() }
            }
            .font(GymupTypography.uiStrong)
            .foregroundStyle(GymupColors.accent)
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            .accessibilityIdentifier("history.serverDetail.retry")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityIdentifier("history.serverDetail.error")
    }
}
