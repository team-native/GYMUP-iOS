import SwiftUI

enum WorkoutCompletionColors {
    static let canvas = Color(red: 11.0 / 255, green: 11.0 / 255, blue: 13.0 / 255)
    static let surface = Color(red: 31.0 / 255, green: 31.0 / 255, blue: 34.0 / 255)
    static let elevatedSurface = Color(red: 42.0 / 255, green: 42.0 / 255, blue: 46.0 / 255)
    static let primaryText = Color.white
    static let secondaryText = Color(red: 158.0 / 255, green: 158.0 / 255, blue: 166.0 / 255)
    static let red = Color(red: 1, green: 18.0 / 255, blue: 22.0 / 255)
    static let gold = Color(red: 1, green: 199.0 / 255, blue: 76.0 / 255)
}

struct WorkoutCompletionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WorkoutCompletionColors.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct WorkoutCompletionPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GymupTypography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(WorkoutCompletionColors.red, in: RoundedRectangle(cornerRadius: 14))
                .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

struct WorkoutCompletionSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GymupTypography.headline)
                .foregroundStyle(WorkoutCompletionColors.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(WorkoutCompletionColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14))
                .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

struct WorkoutCompletionMetricTile: View {
    let metric: WorkoutCompletionData.Metric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(metric.value)
                    .font(Font.custom("BarlowCondensed-ExtraBold", size: 20, relativeTo: .title2))
                    .foregroundStyle(WorkoutCompletionColors.primaryText)

                Text(metric.unit)
                    .font(Font.custom("Archivo-SemiBold", size: 10, relativeTo: .caption))
                    .tracking(0.5)
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
            }

            Text(localizedTitle)
                .font(Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption))
                .foregroundStyle(WorkoutCompletionColors.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(WorkoutCompletionColors.surface, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var localizedTitle: String {
        switch metric.title {
        case "TIME": "시간"
        case "SETS": "세트"
        case "VOLUME": "총 볼륨"
        case "PERSONAL RECORD": "신기록"
        default: metric.title
        }
    }

    private var accessibilityLabel: String {
        let unit = switch metric.title {
        case "TIME": "분"
        case "SETS": "세트"
        case "VOLUME": "킬로그램"
        case "PERSONAL RECORD": "개"
        default: metric.unit
        }
        return "\(localizedTitle), \(metric.value)\(unit)"
    }
}

struct WorkoutCompletionProgressBar: View {
    let value: Double
    var tint: Color = WorkoutCompletionColors.red

    private var progress: Double {
        min(max(value, 0), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(WorkoutCompletionColors.elevatedSurface)

                Capsule()
                    .fill(tint)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 7)
        .accessibilityHidden(true)
    }
}

struct WorkoutCompletionActionBar<Primary: View, Secondary: View>: View {
    let primary: Primary
    let secondary: Secondary

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                secondary
                primary
            }

            VStack(spacing: 10) {
                primary
                secondary
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background {
            WorkoutCompletionColors.canvas
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct WorkoutCompletionHero: View {
    let routineName: String
    let completedAt: String

    @ScaledMetric(relativeTo: .largeTitle) private var heroHeight: CGFloat = 208

    var body: some View {
        GeometryReader { geometry in
            Image("H1RoutinePhoto")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.08), location: 0),
                            .init(color: .clear, location: 0.3),
                            .init(color: .black.opacity(0.84), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WORKOUT COMPLETE")
                            .font(Font.custom("Archivo-SemiBold", size: 10, relativeTo: .caption))
                            .tracking(1.4)
                            .foregroundStyle(WorkoutCompletionColors.red)

                        Text(routineName)
                            .font(Font.custom("BarlowCondensed-Black", size: 34, relativeTo: .title))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(completedAt)
                            .font(Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption))
                            .foregroundStyle(.white.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
        }
        .frame(height: heroHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("운동 완료, \(routineName), \(completedAt)")
    }
}
