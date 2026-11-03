#if DEBUG
import Foundation

private struct DevelopmentTokenRequest: Encodable {
    let userId: String
}

private struct DevelopmentTokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresAt: String
}

actor DevelopmentBearerTokenProvider: BearerTokenProviding {
    private let environment: APIEnvironment
    private let session: URLSession
    private var cachedToken: String?
    private var cachedExpiration: Date?

    init(environment: APIEnvironment, session: URLSession = .shared) {
        self.environment = environment
        self.session = session
    }

    func accessToken() async throws -> String? {
        if let cachedToken, let cachedExpiration,
           cachedExpiration.timeIntervalSinceNow > 30 {
            return cachedToken
        }

        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/auth/dev-token",
            requiresBearerToken: false,
            expectedStatusCode: 200
        )
        var request = URLRequest(url: try environment.url(for: endpoint))
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(DevelopmentTokenRequest(userId: "local-user"))

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard response.statusCode == 200 else {
            if let envelope = try? JSONDecoder().decode(ServerErrorEnvelope.self, from: data) {
                throw APIClientError.server(statusCode: response.statusCode, detail: envelope.detail)
            }
            throw APIClientError.unexpectedStatusCode(response.statusCode)
        }

        let tokenResponse = try JSONDecoder().decode(DevelopmentTokenResponse.self, from: data)
        guard tokenResponse.tokenType.caseInsensitiveCompare("Bearer") == .orderedSame,
              !tokenResponse.accessToken.isEmpty,
              let expiration = Self.date(from: tokenResponse.expiresAt), expiration > .now
        else {
            throw APIClientError.invalidResponse
        }

        cachedToken = tokenResponse.accessToken
        cachedExpiration = expiration
        return tokenResponse.accessToken
    }

    private static func date(from value: String) -> Date? {
        let options: [ISO8601DateFormatter.Options] = [
            [.withInternetDateTime, .withFractionalSeconds],
            [.withInternetDateTime]
        ]
        for formatOptions in options {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = formatOptions
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }
}

actor UITestOnboardingSubmissionService: OnboardingSubmissionServicing {
    private let failsFirstRequest: Bool
    private var didFail = false

    init(failsFirstRequest: Bool) {
        self.failsFirstRequest = failsFirstRequest
    }

    func save(_ request: SaveOnboardingRequest) async throws -> SaveOnboardingResponse {
        if failsFirstRequest && !didFail {
            didFail = true
            throw APIClientError.server(
                statusCode: 400,
                detail: ServerErrorDetail(code: "VALIDATION_ERROR", message: "테스트 서버 오류 메시지")
            )
        }

        return SaveOnboardingResponse(
            userId: "ui-test-user",
            profileCompleted: true,
            experienceLevel: request.experienceLevel,
            goalType: request.goalType,
            weeklyWorkoutTarget: request.weeklyWorkoutTarget
        )
    }
}

enum DebugOnboardingNetworking {
    static func makeService() -> OnboardingAPIService? {
        guard let baseURL = URL(string: "http://localhost:8000"),
              let environment = try? APIEnvironment(baseURL: baseURL)
        else {
            return nil
        }

        let tokenProvider = DevelopmentBearerTokenProvider(environment: environment)
        let client = APIClient(environment: environment, tokenProvider: tokenProvider)
        return OnboardingAPIService(client: client)
    }
}
#endif
