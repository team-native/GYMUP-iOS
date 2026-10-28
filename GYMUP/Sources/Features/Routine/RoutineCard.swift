import SwiftUI

struct RoutineCard: View {
    let routine: RoutinePlan
    let onOpen: () -> Void
    let onStart: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
            Button(action: onOpen) {
                ZStack(alignment: .bottomLeading) {
                    Image(routine.coverAssetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: 140)
                        .clipped()
                    LinearGradient(colors: [.clear, GymupColors.canvas.opacity(0.92)], startPoint: .top, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(routine.name)
                            .font(GymupTypography.display)
                            .foregroundStyle(GymupColors.primaryText)
                            .frame(height: 25)
                        Text(routine.summary)
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                            .frame(height: 15)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 34)
                }
                .overlay(alignment: .topLeading) {
                    if routine.isRecommended {
                        Text("오늘 추천")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(GymupColors.accent, in: Capsule())
                            .padding(.leading, 16)
                            .padding(.top, 14)
                    }
                }
                .frame(width: geometry.size.width, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("routine.card.\(routine.id)")
            Button(action: onStart) {
                    Image("R1IconPlay")
                        .resizable()
                        .frame(width: 14.76, height: 14.76)
                        .frame(width: 36.08, height: 36.08)
                        .background(GymupColors.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(routine.title) 운동 시작")
                .accessibilityIdentifier("routine.start.\(routine.id)")
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .frame(width: geometry.size.width, height: 140)
        }
        .frame(height: 140)
    }
}

struct EmptyRoutineCard: View {
    let onOpen: () -> Void
    let onStart: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 2) {
                Text("빈 루틴")
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(minHeight: 21)
                Text("0종목 · 운동을 추가해야 시작할 수 있어요")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.tertiaryText)
                    .frame(minHeight: 15)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 70)
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            Button(action: onStart) {
                Image("R1IconPlayDisabled")
                    .resizable()
                    .frame(width: 13.12, height: 13.12)
                    .frame(width: 32.8, height: 32.8)
                    .background(GymupColors.elevatedSurface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("빈 루틴 시작 안내")
            .padding(.trailing, 16)
        }
    }
}
