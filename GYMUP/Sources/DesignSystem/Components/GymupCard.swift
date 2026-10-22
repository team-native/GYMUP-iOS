import SwiftUI

struct GymupCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(GymupSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GymupColors.surface,
                in: RoundedRectangle(cornerRadius: GymupRadius.large)
            )
    }
}

#Preview {
    GymupCard {
        Text("콘텐츠를 담는 공용 카드")
            .font(GymupTypography.body)
    }
    .padding()
}
