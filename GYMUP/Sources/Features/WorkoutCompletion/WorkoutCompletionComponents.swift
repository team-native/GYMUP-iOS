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
            Text(metric.title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(WorkoutCompletionColors.secondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(metric.value)
                    .font(GymupTypography.headline)
                    .foregroundStyle(WorkoutCompletionColors.primaryText)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)

                Text(metric.unit)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(WorkoutCompletionColors.surface, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metric.title), \(metric.value) \(metric.unit)")
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

struct WorkoutCompletionBarbellArtwork: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.18, green: 0.18, blue: 0.2), WorkoutCompletionColors.canvas],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(WorkoutCompletionColors.red.opacity(0.16))
                    .frame(width: geometry.size.width * 0.62)
                    .blur(radius: 28)
                    .offset(x: geometry.size.width * 0.28, y: -geometry.size.height * 0.25)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        plateStack
                        Capsule()
                            .fill(Color(red: 0.72, green: 0.73, blue: 0.76))
                            .frame(width: geometry.size.width * 0.37, height: 7)
                        plateStack
                    }
                    .shadow(color: .black.opacity(0.5), radius: 14, y: 9)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 2) {
                    Text("GYMUP · WORKOUT 024")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("UPPER BODY")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .frame(height: 128)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("운동을 마친 바벨 사진 영역")
    }

    private var plateStack: some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 3)
                .fill(WorkoutCompletionColors.red)
                .frame(width: 13, height: 61)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.66, green: 0.08, blue: 0.1))
                .frame(width: 8, height: 48)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.38, green: 0.38, blue: 0.41))
                .frame(width: 6, height: 36)
        }
    }
}
