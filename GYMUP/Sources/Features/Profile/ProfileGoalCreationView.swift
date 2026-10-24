import SwiftUI

struct ProfileGoalCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: ProfileGoalType = .body
    @State private var selectedDuration = 12

    let onStart: (ProfileGoalRecord) -> Void

    private let workoutsPerWeek = 3
    private let durations = [4, 8, 12, 16]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                    VStack(alignment: .leading, spacing: GymupSpacing.small) {
                        Text("새 목표")
                            .font(GymupTypography.homeTitle)
                            .foregroundStyle(GymupColors.primaryText)
                            .accessibilityAddTraits(.isHeader)
                        Text("나에게 맞는 목표를 선택해요")
                            .font(GymupTypography.caption)
                            .foregroundStyle(GymupColors.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: GymupSpacing.small) {
                        sectionTitle("목표 유형")
                        ForEach(ProfileGoalType.allCases) { type in
                            goalTypeCard(type)
                        }
                    }

                    VStack(alignment: .leading, spacing: GymupSpacing.small) {
                        sectionTitle("목표 기간")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: GymupSpacing.small) {
                            ForEach(durations, id: \.self) { duration in
                                durationButton(duration)
                            }
                        }
                    }

                    summaryCard
                }
                .padding(.horizontal, GymupSpacing.large)
                .padding(.top, GymupSpacing.large)
                .padding(.bottom, GymupSpacing.large)
            }

            Button(action: startGoal) {
                Text("목표 시작하기")
                    .font(GymupTypography.uiBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(GymupColors.accent, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, GymupSpacing.large)
            .padding(.top, GymupSpacing.small)
            .padding(.bottom, GymupSpacing.medium)
            .background(GymupColors.canvas)
            .accessibilityHint("선택한 목표를 현재 목표로 설정합니다")
        }
        .background(GymupColors.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            GymupDetailNavigationBar(title: "목표 설정", onBack: { dismiss() })
                .background(GymupColors.canvas)
        }
    }

    private func goalTypeCard(_ type: ProfileGoalType) -> some View {
        let isSelected = selectedType == type
        return Button {
            selectedType = type
        } label: {
            HStack(spacing: GymupSpacing.medium) {
                Image(systemName: icon(for: type))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? GymupColors.brandText : GymupColors.secondaryText)
                    .frame(width: 38, height: 38)
                    .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.small))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    Text(type.rawValue)
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                    Text(type.description)
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(GymupColors.accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(GymupSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: GymupRadius.medium)
                    .strokeBorder(isSelected ? GymupColors.accent : GymupColors.border, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(type.rawValue), \(type.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func durationButton(_ duration: Int) -> some View {
        let isSelected = selectedDuration == duration
        return Button {
            selectedDuration = duration
        } label: {
            Text("\(duration)주")
                .font(GymupTypography.uiStrong)
                .foregroundStyle(isSelected ? GymupColors.primaryText : GymupColors.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.small))
                .overlay {
                    RoundedRectangle(cornerRadius: GymupRadius.small)
                        .strokeBorder(isSelected ? GymupColors.accent : GymupColors.border, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("목표 기간 \(duration)주")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.medium) {
            sectionTitle("목표 요약")
            HStack(alignment: .top, spacing: GymupSpacing.medium) {
                Image(systemName: "target")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(GymupColors.brandText)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    Text("\(selectedType.rawValue) · \(selectedDuration)주")
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                    Text("주 \(workoutsPerWeek)회 · 총 \(selectedDuration * workoutsPerWeek)회")
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                    Text("Growth 0/100")
                        .font(GymupTypography.metric)
                        .foregroundStyle(GymupColors.brandText)
                }
            }
        }
        .padding(GymupSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
        .accessibilityElement(children: .combine)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(GymupTypography.label)
            .foregroundStyle(GymupColors.secondaryText)
            .frame(minHeight: 20, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    private func icon(for type: ProfileGoalType) -> String {
        switch type {
        case .body: "figure.cooldown"
        case .strength: "dumbbell.fill"
        case .consistency: "calendar.badge.checkmark"
        }
    }

    private func startGoal() {
        onStart(
            ProfileGoalRecord(
                type: selectedType,
                workoutsPerWeek: workoutsPerWeek,
                durationWeeks: selectedDuration,
                period: "진행 중",
                growth: 0,
                completedWeeks: 0,
                isCurrent: true
            )
        )
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ProfileGoalCreationView(onStart: { _ in })
            .preferredColorScheme(.dark)
    }
}
