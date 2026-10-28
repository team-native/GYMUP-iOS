import SwiftUI

struct WorkoutSessionRestTimerScreen: View {
    let exercise: WorkoutSessionExercise
    let completedSetCount: Int
    let nextSetIndex: Int
    let remainingSeconds: Int
    let totalSeconds: Int
    let onExtend: () -> Void
    let onSkip: () -> Void
    @State private var isPlateCalculatorPresented = false

    private var nextSet: WorkoutSessionSet { exercise.sets[nextSetIndex] }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    restHeading
                    countdown
                        .padding(.top, 62)
                    totalDuration
                        .padding(.top, 77)
                    progressBar
                        .padding(.top, 26)
                    timerActions
                        .padding(.top, 24)
                    nextSetCard
                        .padding(.top, 24)
                    Spacer(minLength: 64)
                    plateCalculatorHint
                }
                .padding(.horizontal, 20)
                .padding(.top, max(0, 164 - geometry.frame(in: .global).minY))
                .padding(.bottom, 24)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .opacity(isPlateCalculatorPresented ? 0 : 1)
            .accessibilityHidden(isPlateCalculatorPresented)
        }
        .background {
            ZStack(alignment: .top) {
                GymupColors.canvas
                if isPlateCalculatorPresented {
                    GeometryReader { proxy in
                        Image("W10BackgroundPhoto")
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: min(proxy.size.height, proxy.size.width * 0.76))
                            .clipped()
                            .overlay(alignment: .bottom) {
                                LinearGradient(
                                    colors: [.clear, GymupColors.canvas],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: min(proxy.size.height, proxy.size.width * 0.76))
                            }
                            .overlay(GymupColors.canvas.opacity(0.35))
                    }
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isPlateCalculatorPresented) {
            WorkoutPlateCalculatorSheet(target: nextSet.weightKilograms)
        }
    }

    private var restHeading: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REST")
                .font(GymupTypography.label)
                .tracking(0.16)
                .foregroundStyle(GymupColors.brandText)
            Text("\(exercise.name) \(completedSetCount)세트 완료")
                .font(GymupTypography.uiMedium)
                .foregroundStyle(GymupColors.secondaryText)
        }
    }

    private var countdown: some View {
        Text(timeString(remainingSeconds))
            .font(.custom("BarlowCondensed-Black", size: 106))
            .tracking(-1)
            .foregroundStyle(GymupColors.primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .accessibilityLabel("휴식 남은 시간 \(spokenDuration(remainingSeconds))")
            .accessibilityIdentifier("workout.rest.countdown")
    }

    private var totalDuration: some View {
        Text("/ \(timeString(totalSeconds))")
            .font(.custom("BarlowCondensed-ExtraBold", size: 18))
            .tracking(0.13)
            .foregroundStyle(GymupColors.secondaryText)
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            let duration = max(totalSeconds, 1)
            let elapsedFraction = 1 - min(max(Double(remainingSeconds) / Double(duration), 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(GymupColors.overlay)
                Capsule()
                    .fill(GymupColors.accent)
                    .frame(width: geometry.size.width * elapsedFraction)
            }
        }
        .frame(height: 6)
        .accessibilityLabel("휴식 진행")
        .accessibilityValue("\(max(totalSeconds - remainingSeconds, 0))초 경과")
    }

    private var timerActions: some View {
        HStack(spacing: 10) {
            Button(action: onExtend) {
                Text("+15초")
                    .font(GymupTypography.uiBold)
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(GymupColors.elevatedSurface, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(totalSeconds >= 600)
            .opacity(totalSeconds >= 600 ? 0.45 : 1)
            .accessibilityIdentifier("workout.rest.extend")

            Button(action: onSkip) {
                Text("건너뛰기")
                    .font(GymupTypography.uiBold)
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .overlay(Capsule().strokeBorder(GymupColors.strongBorder, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("workout.rest.skip")
        }
        .frame(height: 56)
    }

    private var nextSetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Image(exercise.imageAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 0) {
                    Text("NEXT · SET \(nextSetIndex + 1) / \(exercise.sets.count)")
                        .font(GymupTypography.label)
                        .tracking(0.16)
                        .foregroundStyle(GymupColors.secondaryText)
                    Text("\(nextSet.weightKilograms.formatted(.number.precision(.fractionLength(0...1)))) KG × "
                         + "\(nextSet.repetitions)\(exercise.measure == .seconds ? "초" : "")")
                        .font(GymupTypography.display)
                        .foregroundStyle(GymupColors.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("\(exercise.name) · 이전 \(exercise.previousPerformance(for: nextSetIndex) ?? "—")")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                isPlateCalculatorPresented = true
            } label: {
                HStack(spacing: 8) {
                Image("H5IconTarget")
                    .resizable()
                    .frame(width: 16, height: 16)
                Text("원판 계산 보기 · V2")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.brandText)
            }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("workout.plate.open")
        }
        .padding(16)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var plateCalculatorHint: some View {
        Text("잠금화면 · Live Activity 미리보기")
            .font(GymupTypography.uiCaption)
            .underline()
            .foregroundStyle(GymupColors.brandText)
            .frame(maxWidth: .infinity)
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", max(seconds, 0) / 60, max(seconds, 0) % 60)
    }

    private func spokenDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes == 0 { return "\(remainder)초" }
        return remainder == 0 ? "\(minutes)분" : "\(minutes)분 \(remainder)초"
    }
}
