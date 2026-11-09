import Foundation

enum APIEnvironmentConfiguration {
    static let baseURLInfoPlistKey = "GYMUP_API_BASE_URL"

    static func makeEnvironment(from bundle: Bundle = .main) -> APIEnvironment? {
        guard
            let configuredValue = bundle.object(forInfoDictionaryKey: baseURLInfoPlistKey) as? String
        else {
            return nil
        }

        let trimmedValue = configuredValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, let baseURL = URL(string: trimmedValue) else {
            return nil
        }

        return try? APIEnvironment(baseURL: baseURL)
    }
}

struct APIServiceContainer {
    let environment: APIEnvironment
    private let client: APIClient

    init?(
        bundle: Bundle = .main,
        tokenProviderFactory: (APIEnvironment) -> BearerTokenProviding?
    ) {
        guard
            let environment = APIEnvironmentConfiguration.makeEnvironment(from: bundle),
            let tokenProvider = tokenProviderFactory(environment)
        else {
            return nil
        }

        self.init(environment: environment, tokenProvider: tokenProvider)
    }

    init(environment: APIEnvironment, tokenProvider: BearerTokenProviding) {
        self.environment = environment
        client = APIClient(environment: environment, tokenProvider: tokenProvider)
    }

    var onboarding: OnboardingAPIService { OnboardingAPIService(client: client) }
    var goalProgress: GoalAPIService { GoalAPIService(client: client) }
    var currentWeeklyGoal: CurrentWeeklyGoalAPIService { CurrentWeeklyGoalAPIService(client: client) }
    var userSettings: UserSettingsAPIService { UserSettingsAPIService(client: client) }
    var plateCalculator: PlateCalculatorAPIService { PlateCalculatorAPIService(client: client) }
    var exerciseRead: ExerciseReadAPIService { ExerciseReadAPIService(client: client) }
    var routine: RoutineAPIService { RoutineAPIService(client: client) }
    var workoutSession: WorkoutSessionAPIService { WorkoutSessionAPIService(client: client) }
    var workoutRead: WorkoutReadAPIService { WorkoutReadAPIService(client: client) }
    var workoutHistory: WorkoutHistoryAPIService { WorkoutHistoryAPIService(client: client) }
    var photos: PhotosAPIService { PhotosAPIService(client: client) }
    var level: LevelAPIService { LevelAPIService(client: client) }
    var weeklyStreak: WeeklyStreakAPIService { WeeklyStreakAPIService(client: client) }
}
