import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

extension WorkoutPhotoFilter {
    var saturation: Double {
        switch self {
        case .natural: 1
        case .pump: 1.2
        case .definition: 0.92
        case .mirror: 1.05
        }
    }

    var contrast: Double {
        switch self {
        case .natural: 1
        case .pump: 1.08
        case .definition: 1.22
        case .mirror: 1.02
        }
    }

    var brightness: Double {
        self == .mirror ? 0.025 : 0
    }

    var overlayColor: Color {
        switch self {
        case .natural: .clear
        case .pump: WorkoutCompletionColors.red.opacity(0.1)
        case .definition: Color.blue.opacity(0.08)
        case .mirror: Color.white.opacity(0.04)
        }
    }
}

struct WorkoutPhotoImagePreview: View {
    let image: UIImage
    let filter: WorkoutPhotoFilter
    var adjustments = WorkoutPhotoAdjustments()

    private static let context = CIContext()

    var body: some View {
        Image(uiImage: adjustedImage)
            .resizable()
            .scaledToFill()
            .scaleEffect(x: filter == .mirror ? -1 : 1, y: 1)
            .overlay(filter.overlayColor.blendMode(.softLight))
            .clipped()
    }

    private var adjustedImage: UIImage {
        guard let source = CIImage(image: image) else { return image }

        let colorAdjusted = source.applyingFilter(
            "CIColorControls",
            parameters: [
                kCIInputSaturationKey: filter.saturation,
                kCIInputContrastKey: filter.contrast * (1 + adjustments.contrast / 100),
                kCIInputBrightnessKey: filter.brightness + adjustments.shadow / 100
            ]
        )
        let sharpened = colorAdjusted.applyingFilter(
            "CISharpenLuminance",
            parameters: [kCIInputSharpnessKey: min(max(0.4 + adjustments.sharpness / 50, 0), 2)]
        )

        guard let output = Self.context.createCGImage(sharpened, from: sharpened.extent) else { return image }
        return UIImage(cgImage: output, scale: image.scale, orientation: image.imageOrientation)
    }
}

struct WorkoutPhotoFilterSelector: View {
    @Binding var selection: WorkoutPhotoFilter

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(WorkoutPhotoFilter.allCases) { filter in
                    Button {
                        selection = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(GymupTypography.callout)
                            .foregroundStyle(selection == filter ? .white : WorkoutCompletionColors.secondaryText)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .background {
                                Capsule()
                                    .fill(selection == filter ? WorkoutCompletionColors.red : WorkoutCompletionColors.surface)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == filter ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }
}

struct WorkoutPhotoAdjustmentSlider: View {
    let title: String
    @Binding var value: Double

    private var formattedValue: String {
        value.formatted(
            .number
                .sign(strategy: .always(includingZero: false))
                .precision(.fractionLength(0))
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(GymupTypography.callout)
                    .foregroundStyle(WorkoutCompletionColors.primaryText)

                Spacer()

                Text(formattedValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    .accessibilityLabel("\(title) \(formattedValue)")
            }

            Slider(value: $value, in: -50 ... 50, step: 1)
                .tint(WorkoutCompletionColors.red)
                .accessibilityLabel(title)
                .accessibilityValue(formattedValue)
        }
        .padding(.vertical, 4)
    }
}

struct WorkoutPhotoStampOverlay: View {
    let data: WorkoutCompletionData
    let style: WorkoutPhotoStampStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("GYMUP")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.6)
                    Text(data.completedAt.components(separatedBy: " · ").first ?? data.completedAt)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }

                Spacer()

                Text(data.routineName)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(WorkoutCompletionColors.red, in: Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                ForEach(data.metrics.prefix(3)) { metric in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.title == "TIME" ? "TIME" : metric.title == "SETS" ? "SETS" : "VOLUME")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(.white.opacity(0.72))
                        Text("\(metric.value) \(metric.unit)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("GROWTH")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.72))
                    Text("\(data.previousGrowth) → \(data.growth)  +\(data.earnedXP) XP")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            switch style {
            case .card:
                WorkoutCompletionColors.canvas.opacity(0.78)
            case .minimal:
                WorkoutCompletionColors.canvas.opacity(0.48)
            case .bold:
                LinearGradient(
                    colors: [WorkoutCompletionColors.red.opacity(0.88), WorkoutCompletionColors.canvas.opacity(0.92)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case .stamp:
                WorkoutCompletionColors.red.opacity(0.84)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: style == .minimal ? 8 : 14))
        .padding(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(data.routineName), 성장도 \(data.previousGrowth)에서 \(data.growth), \(data.earnedXP) 경험치")
    }
}

struct WorkoutPhotoStampStyleSelector: View {
    @Binding var selection: WorkoutPhotoStampStyle

    var body: some View {
        HStack(spacing: 8) {
            ForEach(WorkoutPhotoStampStyle.allCases) { style in
                Button {
                    selection = style
                } label: {
                    Text(style.rawValue)
                        .font(GymupTypography.caption)
                        .foregroundStyle(selection == style ? .white : WorkoutCompletionColors.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 11)
                                .fill(selection == style ? WorkoutCompletionColors.red : WorkoutCompletionColors.surface)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == style ? .isSelected : [])
            }
        }
    }
}
