import SwiftUI

struct ProfilePhotoPermissionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                Text("오운완 사진 촬영과 저장에 필요한 권한을 안내해요.")
                    .font(GymupTypography.body)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    permissionRow(
                        icon: "camera",
                        title: "카메라",
                        detail: "사진 촬영 시 앱에서 요청합니다"
                    )
                    separator
                    permissionRow(
                        icon: "photo.on.rectangle",
                        title: "사진 보관함",
                        detail: "사진 선택 시 앱에서 요청합니다"
                    )
                }
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))

                HStack(alignment: .top, spacing: GymupSpacing.small) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(GymupColors.brandText)
                        .accessibilityHidden(true)
                    Text(
                        "현재는 권한을 요청하거나 기기 설정을 바꾸지 않아요. "
                            + "실제 사진 기능을 사용할 때 필요한 권한을 안내하는 화면입니다."
                    )
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(GymupSpacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            }
            .padding(.horizontal, GymupSpacing.large)
            .padding(.top, GymupSpacing.large)
            .padding(.bottom, GymupSpacing.xxLarge)
        }
        .background(GymupColors.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            GymupDetailNavigationBar(title: "카메라 · 사진 권한", onBack: { dismiss() })
                .background(GymupColors.canvas)
        }
    }

    private func permissionRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: GymupSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(GymupColors.primaryText)
                .frame(width: 36, height: 36)
                .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.small))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                Text(title)
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                Text(detail)
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("미요청")
                .font(GymupTypography.label)
                .foregroundStyle(GymupColors.secondaryText)
        }
        .padding(GymupSpacing.medium)
        .frame(minHeight: 68)
        .accessibilityElement(children: .combine)
    }

    private var separator: some View {
        Rectangle()
            .fill(GymupColors.border)
            .frame(height: 1)
            .padding(.leading, 56)
    }
}

#Preview {
    NavigationStack {
        ProfilePhotoPermissionView()
            .preferredColorScheme(.dark)
    }
}
