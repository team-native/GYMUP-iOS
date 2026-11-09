import Foundation

struct ListPhotosQuery {
    let cursor: String?
    let size: Int
    let from: String
    let endDate: String
    let sort: String

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "size", value: String(size)),
            URLQueryItem(name: "from", value: from),
            URLQueryItem(name: "to", value: endDate),
            URLQueryItem(name: "sort", value: sort)
        ]
        if let cursor {
            items.insert(URLQueryItem(name: "cursor", value: cursor), at: 0)
        }
        return items
    }
}

struct PhotoListItem: Codable, Equatable {
    let photoId: String
    let workoutId: String
    let capturedAt: String
    let thumbnailUrl: String?
}

struct ListPhotosResponse: Codable, Equatable {
    let items: [PhotoListItem]
    let nextCursor: String?
}

struct PhotoDownloadURLResponse: Codable, Equatable {
    let photoId: String
    let downloadUrl: String
    let expiresAt: String
}

enum PhotoProcessingJobStatus: String, Codable {
    case processing = "PROCESSING"
}

struct CreatePhotoStampRequest: Codable, Equatable {
    let layoutId: String
    let fields: [String]
}

struct CreatePhotoProcessingJobResponse: Codable, Equatable {
    let jobId: String
    let photoId: String
    let status: PhotoProcessingJobStatus
}

struct PhotoFilterAdjustments: Codable, Equatable {
    let contrast: Double
    let shadow: Double
    let sharpness: Double
    let highlight: Double
    let tone: Double
}

struct CreatePhotoFilterRequest: Codable, Equatable {
    let preset: String
    let adjustments: PhotoFilterAdjustments
}

struct RequestWorkoutPhotoUploadRequest: Codable, Equatable {
    let fileName: String
    let contentType: String
    let size: Int
}

struct RequestWorkoutPhotoUploadResponse: Codable, Equatable {
    let photoId: String
    let uploadUrl: String
    let uploadHeaders: JSONValue
    let expiresAt: String
}

struct PhotosAPIService {
    private let client: APIClient
    private let uploadSession: URLSession

    init(client: APIClient) {
        self.init(client: client, uploadSession: Self.makeUploadSession())
    }

    init(client: APIClient, uploadSession: URLSession) {
        self.client = client
        self.uploadSession = uploadSession
    }

    func list(_ query: ListPhotosQuery) async throws -> ListPhotosResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/photos",
            queryItems: query.queryItems,
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: ListPhotosResponse.self)
    }

    func downloadURL(photoId: String) async throws -> PhotoDownloadURLResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/photos/\(photoId)/download-url",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: PhotoDownloadURLResponse.self)
    }

    func createStamp(photoId: String, request: CreatePhotoStampRequest) async throws -> CreatePhotoProcessingJobResponse {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/photos/\(photoId)/stamps",
            expectedStatusCode: 202
        )
        return try await client.send(endpoint, body: request, as: CreatePhotoProcessingJobResponse.self)
    }

    func applyFilter(photoId: String, request: CreatePhotoFilterRequest) async throws -> CreatePhotoProcessingJobResponse {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/photos/\(photoId)/filters",
            expectedStatusCode: 202
        )
        return try await client.send(endpoint, body: request, as: CreatePhotoProcessingJobResponse.self)
    }

    func requestWorkoutPhotoUpload(
        workoutId: String,
        request: RequestWorkoutPhotoUploadRequest
    ) async throws -> RequestWorkoutPhotoUploadResponse {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/workouts/\(workoutId)/photos",
            expectedStatusCode: 201
        )
        return try await client.send(endpoint, body: request, as: RequestWorkoutPhotoUploadResponse.self)
    }

    func uploadWorkoutPhoto(
        _ imageData: Data,
        using upload: RequestWorkoutPhotoUploadResponse,
        now: Date = .now
    ) async throws {
        guard let url = URL(string: upload.uploadUrl), url.scheme?.lowercased() == "https", url.host != nil else {
            throw WorkoutPhotoStorageUploadError.invalidURL
        }

        guard let expiration = Self.date(from: upload.expiresAt), expiration > now else {
            throw WorkoutPhotoStorageUploadError.expired
        }

        guard case let .object(headers) = upload.uploadHeaders else {
            throw WorkoutPhotoStorageUploadError.invalidHeaders
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        for (name, value) in headers {
            guard case let .string(stringValue) = value,
                  !name.isEmpty,
                  !stringValue.contains("\r"),
                  !stringValue.contains("\n") else {
                throw WorkoutPhotoStorageUploadError.invalidHeaders
            }
            request.setValue(stringValue, forHTTPHeaderField: name)
        }

        let (_, response) = try await uploadSession.upload(for: request, from: imageData)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw WorkoutPhotoStorageUploadError.httpStatus(statusCode)
        }
    }

    private static func makeUploadSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        let redirectDelegate = PhotoUploadRedirectDelegate()
        return URLSession(configuration: configuration, delegate: redirectDelegate, delegateQueue: nil)
    }

    private static func date(from value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }
}

enum WorkoutPhotoStorageUploadError: Error, Equatable {
    case invalidURL
    case expired
    case invalidHeaders
    case httpStatus(Int)

    var isRetryable: Bool {
        if case let .httpStatus(statusCode) = self {
            return (500..<600).contains(statusCode)
        }
        return false
    }
}

final class PhotoUploadRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        guard let originalURL = task.originalRequest?.url,
              let destinationURL = request.url,
              hasSameOrigin(originalURL, destinationURL) else {
            completionHandler(nil)
            return
        }

        completionHandler(request)
    }

    private func hasSameOrigin(_ firstURL: URL, _ secondURL: URL) -> Bool {
        guard let firstScheme = firstURL.scheme?.lowercased(),
              let secondScheme = secondURL.scheme?.lowercased(),
              let firstHost = firstURL.host?.lowercased(),
              let secondHost = secondURL.host?.lowercased() else { return false }

        return firstScheme == secondScheme
            && firstHost == secondHost
            && effectivePort(for: firstURL) == effectivePort(for: secondURL)
    }

    private func effectivePort(for url: URL) -> Int? {
        if let port = url.port { return port }
        switch url.scheme?.lowercased() {
        case "https": 443
        case "http": 80
        default: nil
        }
    }
}

protocol PhotosListing {
    func list(_ query: ListPhotosQuery) async throws -> ListPhotosResponse
}

extension PhotosAPIService: PhotosListing {}

protocol PhotosDownloading {
    func downloadURL(photoId: String) async throws -> PhotoDownloadURLResponse
}

extension PhotosAPIService: PhotosDownloading {}
