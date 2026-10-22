import SwiftUI

enum GymupTab: Hashable {
    case home
    case routine
    case history
    case profile
}

struct MainTabView: View {
    @State private var selection: GymupTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(onOpenRoutines: { selection = .routine })
                .tabItem { Label("홈", systemImage: "house.fill") }
                .tag(GymupTab.home)

            RoutineView()
                .tabItem { Label("루틴", systemImage: "list.bullet.rectangle") }
                .tag(GymupTab.routine)

            HistoryPlaceholderView()
                .tabItem { Label("기록", systemImage: "chart.bar.fill") }
                .tag(GymupTab.history)

            ProfilePlaceholderView()
                .tabItem { Label("마이", systemImage: "person.fill") }
                .tag(GymupTab.profile)
        }
        .tint(GymupColors.accent)
        .preferredColorScheme(.dark)
    }
}

private struct HistoryPlaceholderView: View {
    var body: some View {
        NavigationStack {
            GymupEmptyState(symbol: "chart.bar", title: "운동 기록", message: "운동을 완료하면 기록이 쌓여요.")
                .background(GymupColors.canvas)
                .navigationTitle("기록")
        }
    }
}

private struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            GymupEmptyState(symbol: "person", title: "내 프로필", message: "내 운동 정보를 확인할 수 있어요.")
                .background(GymupColors.canvas)
                .navigationTitle("마이")
        }
    }
}
