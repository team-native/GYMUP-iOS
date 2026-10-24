import SwiftUI

struct HistoryNavigationBar: View {
    let title: String
    let onBack: () -> Void
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")

            Spacer(minLength: 0)
            Text(title)
                .font(GymupTypography.uiStrong)
                .foregroundStyle(GymupColors.primaryText)
                .lineLimit(1)
            Spacer(minLength: 0)

            if let actionTitle {
                Button(actionTitle) { action?() }
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.brandText)
                    .frame(minWidth: 44, minHeight: 44)
                    .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
    }
}

struct HistoryCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GymupColors.surface,
                in: RoundedRectangle(cornerRadius: GymupRadius.large, style: .continuous)
            )
    }
}

struct HistorySectionTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(GymupTypography.sectionTitle)
                .foregroundStyle(GymupColors.primaryText)
            if let subtitle {
                Text(subtitle)
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            Spacer(minLength: 0)
        }
    }
}

struct HistoryMetricCell: View {
    let value: String
    let unit: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(GymupTypography.metric)
                    .foregroundStyle(GymupColors.primaryText)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Text(unit)
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            Text(title)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct HistoryWorkoutPhoto: View {
    let assetName: String

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFill()
            .clipped()
    }
}

enum HistoryDateText {
    static func string(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar.current
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

}
