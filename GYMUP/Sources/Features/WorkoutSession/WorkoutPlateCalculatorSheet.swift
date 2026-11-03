import SwiftUI

struct WorkoutPlateCalculatorSheet: View {
    let target: Double
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WorkoutPlateCalculatorViewModel

    init(target: Double) {
        self.target = target
#if DEBUG
        let service: WorkoutPlateCalculating? = DebugOnboardingNetworking.makePlateCalculatorService()
#else
        let service: WorkoutPlateCalculating? = nil
#endif
        _viewModel = State(initialValue: WorkoutPlateCalculatorViewModel(target: target, service: service))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("원판 계산").font(GymupTypography.homeTitle)
                    Spacer()
                    Text("V2").font(GymupTypography.label)
                        .foregroundStyle(GymupColors.secondaryText)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(GymupColors.elevatedSurface, in: Capsule())
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(weight(target)).font(GymupTypography.routineTitle)
                    Text("KG 목표").font(GymupTypography.uiStrong).foregroundStyle(GymupColors.secondaryText)
                }
                Image("W10Equipment")
                    .resizable().scaledToFit().frame(maxWidth: 320).frame(height: 180)
                    .frame(maxWidth: .infinity).accessibilityHidden(true)
                row("바", "20 kg")
                row("양쪽 각각", plateDescription)
                if let response = viewModel.response {
                    row("실제 총중량", "\(weight(response.actualWeight)) kg")
                    if !response.achievable {
                        row("목표보다 부족", "\(weight(response.remainder)) kg")
                    }
                }
                row("사용 가능 원판", "25 · 20 · 15 · 10 · 5 · 2.5 · 1.25")
                calculationFeedback
                Button("닫기") { dismiss() }
                    .font(GymupTypography.sectionTitle)
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(GymupColors.elevatedSurface, in: Capsule())
                    .accessibilityIdentifier("workout.plate.close")
            }
            .foregroundStyle(GymupColors.primaryText)
            .padding(.horizontal, 20).padding(.top, 28).padding(.bottom, 24)
        }
        .background(GymupColors.surface.ignoresSafeArea())
        .presentationDetents([.height(555)])
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
        .task { await viewModel.calculateIfAvailable() }
    }

    private var plateDescription: String {
        guard let response = viewModel.response else {
            return viewModel.isCalculating ? "계산 중..." : "계산 불가"
        }
        guard !response.eachSide.isEmpty else { return "원판 없음" }
        return response.eachSide
            .sorted { $0.weight > $1.weight }
            .map { plate in
                let count = plate.count > 1 ? " × \(plate.count)" : ""
                return "\(weight(plate.weight)) kg\(count)"
            }
            .joined(separator: " + ")
    }

    @ViewBuilder
    private var calculationFeedback: some View {
        if viewModel.isCalculating {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(GymupColors.brandText)
                    .accessibilityHidden(true)
                Text("가장 가까운 조합을 확인하고 있어요.")
                    .font(GymupTypography.uiMedium)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(GymupColors.secondaryText)
            .accessibilityElement(children: .combine)
        } else if let errorMessage = viewModel.serverErrorMessage {
            VStack(alignment: .leading, spacing: 4) {
                Label {
                    Text(errorMessage)
                        .font(GymupTypography.uiMedium)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .accessibilityHidden(true)
                }
                .foregroundStyle(GymupColors.accent)
                .accessibilityIdentifier("workout.plate.serverError")

                if viewModel.canRetry {
                    Button {
                        Task { await viewModel.retry() }
                    } label: {
                        Text("다시 시도")
                            .font(GymupTypography.uiBold)
                            .foregroundStyle(GymupColors.brandText)
                            .frame(minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("원판 계산 다시 시도")
                    .accessibilityHint("같은 목표 중량으로 서버에 다시 요청합니다")
                    .accessibilityIdentifier("workout.plate.retry")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if viewModel.response == nil {
            Text(viewModel.isValidTarget
                 ? "정확한 조합을 만들 수 없어요. 2.5kg 단위로 조정해 주세요."
                 : "20kg 이상, 999kg 이하 중량을 입력해 주세요.")
                .font(GymupTypography.uiMedium)
                .foregroundStyle(GymupColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func weight(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(GymupTypography.uiMedium).foregroundStyle(GymupColors.secondaryText)
            Spacer(minLength: 10)
            Text(value).font(GymupTypography.uiStrong).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { GymupColors.border.frame(height: 1) }
    }
}
