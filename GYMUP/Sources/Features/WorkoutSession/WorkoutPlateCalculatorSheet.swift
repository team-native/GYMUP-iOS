import SwiftUI

struct WorkoutPlateCalculatorSheet: View {
    let target: Double
    @Environment(\.dismiss) private var dismiss

    private var plates: [Double]? { WorkoutPlateCalculator.platesPerSide(for: target) }

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
                row("사용 가능 원판", "25 · 20 · 15 · 10 · 5 · 2.5 · 1.25")
                if plates == nil {
                    Text("20kg 이상, 2.5kg 단위의 중량을 입력해 주세요.")
                        .font(GymupTypography.uiMedium).foregroundStyle(GymupColors.secondaryText)
                }
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
    }

    private var plateDescription: String {
        guard let plates else { return "계산 불가" }
        return plates.isEmpty ? "원판 없음" : plates.map { "\(weight($0)) kg" }.joined(separator: " + ")
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
