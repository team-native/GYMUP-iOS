import SwiftUI

struct HomeView: View {
    let onOpenRoutines: () -> Void
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                    header
                    growthCard
                    todayRoutine
                    weeklyActivity
                    recentWorkout
                }
                .padding(.horizontal, GymupSpacing.large)
                .padding(.top, GymupSpacing.medium)
                .padding(.bottom, GymupSpacing.xxLarge)
            }
            .background(GymupColors.canvas)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("GYMUP")
                    .font(GymupTypography.headline)
                    .tracking(1.2)
                Text("오늘도 한 단계 성장해요")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            Spacer()
            Image(systemName: "bell")
                .font(.system(size: 18, weight: .medium))
                .frame(width: 44, height: 44)
                .background(GymupColors.surface, in: Circle())
        }
        .foregroundStyle(GymupColors.primaryText)
    }

    private var growthCard: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.large) {
            HStack {
                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    Text("MY GROWTH")
                        .font(GymupTypography.caption.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(GymupColors.secondaryText)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(viewModel.growth)")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                        Text("LV")
                            .font(GymupTypography.callout.weight(.bold))
                            .foregroundStyle(GymupColors.accent)
                    }
                }
                Spacer()
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(GymupColors.accent)
                    .rotationEffect(.degrees(-18))
                    .frame(width: 82, height: 82)
                    .background(GymupColors.accent.opacity(0.12), in: Circle())
            }
            VStack(alignment: .leading, spacing: GymupSpacing.small) {
                HStack {
                    Text("다음 성장까지")
                    Spacer()
                    Text("\(viewModel.experiencePoints) / \(viewModel.nextLevelXP) XP")
                        .monospacedDigit()
                }
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
                ProgressView(value: Double(viewModel.experiencePoints), total: Double(viewModel.nextLevelXP))
                    .tint(GymupColors.accent)
            }
        }
        .padding(GymupSpacing.large)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
    }

    private var todayRoutine: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.medium) {
            GymupSectionHeader(title: "오늘의 루틴", actionTitle: "전체 보기", action: onOpenRoutines)
            Button(action: onOpenRoutines) {
                HStack(spacing: GymupSpacing.medium) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(GymupColors.accent)
                        .frame(width: 52, height: 52)
                        .background(GymupColors.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: GymupRadius.medium))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.todayRoutine)
                            .font(GymupTypography.headline)
                        Text("가슴 · 어깨 · 삼두  ·  6개 운동")
                            .font(GymupTypography.caption)
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(GymupColors.secondaryText)
                }
                .foregroundStyle(GymupColors.primaryText)
                .padding(GymupSpacing.medium)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            }
            .buttonStyle(.plain)
        }
    }

    private var weeklyActivity: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.medium) {
            GymupSectionHeader(title: "이번 주 운동")
            HStack(alignment: .bottom, spacing: GymupSpacing.medium) {
                ForEach(Array(viewModel.weekDays.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: GymupSpacing.small) {
                        Capsule()
                            .fill(viewModel.activeDays.contains(index) ? GymupColors.accent : GymupColors.elevatedSurface)
                            .frame(height: viewModel.activeDays.contains(index) ? 48 : 24)
                        Text(day)
                            .font(GymupTypography.caption)
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(GymupSpacing.large)
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            HStack(spacing: GymupSpacing.small) {
                Text("3")
                    .foregroundStyle(GymupColors.accent)
                Text("/ 4회 목표")
                Spacer()
                Text("이번 주도 꾸준히 쌓이는 중")
                    .foregroundStyle(GymupColors.secondaryText)
            }
            .font(GymupTypography.caption.weight(.semibold))
        }
    }

    private var recentWorkout: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.medium) {
            GymupSectionHeader(title: "최근 운동", actionTitle: "모두 보기") {}
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("UPPER A")
                        .font(GymupTypography.callout.weight(.bold))
                    Text("어제 · 58분 · 18세트")
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                }
                Spacer()
                Text("+380 XP")
                    .font(GymupTypography.caption.weight(.bold))
                    .foregroundStyle(GymupColors.accent)
            }
            .padding(GymupSpacing.medium)
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
        }
    }
}

#Preview {
    HomeView(onOpenRoutines: {})
}
