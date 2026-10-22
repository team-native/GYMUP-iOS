import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                VStack(alignment: .leading, spacing: GymupSpacing.small) {
                    Text("GYMUP")
                        .font(GymupTypography.largeTitle)
                        .foregroundStyle(GymupColors.primaryText)

                    Text("디자인 시스템 미리보기")
                        .font(GymupTypography.body)
                        .foregroundStyle(GymupColors.secondaryText)
                }

                GymupCard {
                    VStack(alignment: .leading, spacing: GymupSpacing.large) {
                        GymupSectionHeader(title: "공용 컴포넌트")

                        GymupTextField(
                            title: "이름 입력 예시",
                            placeholder: "이름을 입력하세요",
                            text: $viewModel.name
                        )

                        Text(viewModel.greeting)
                            .font(GymupTypography.body)
                            .foregroundStyle(GymupColors.primaryText)

                        GymupButton(
                            title: viewModel.hasStarted ? "준비 완료" : "주요 버튼 예시",
                            action: viewModel.start
                        )

                        GymupButton(
                            title: "보조 버튼 예시",
                            variant: .secondary
                        ) {}
                    }
                }

                GymupCard {
                    VStack(alignment: .leading, spacing: GymupSpacing.medium) {
                        GymupSectionHeader(title: "빈 상태 예시", actionTitle: "안내") {}
                        GymupEmptyState(
                            symbol: "figure.run",
                            title: "아직 운동 기록이 없어요",
                            message: "운동 기록이 생기면 이곳에 표시됩니다."
                        )
                    }
                }
            }
            .padding(GymupSpacing.large)
        }
        .background(GymupColors.canvas)
    }
}

#Preview {
    HomeView()
}
