import Foundation

struct ListPhotosQuery {
    let cursor: String
    let size: Int
    let from: String
    let endDate: String
    let sort: String

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "cursor", value: cursor),
            URLQueryItem(name: "size", value: String(size)),
            URLQueryItem(name: "from", value: from),
            URLQueryItem(name: "to", value: endDate),
            URLQueryItem(name: "sort", value: sort)
        ]
    }
}

struct PhotoListItem: Codable, Equatable {
    let photoId: String
    let workoutId: String
    let capturedAt: String
    let thumbnailUrl: String
}

struct ListPhotosResponse: Codable, Equatable {
    let items: [PhotoListItem]
    let nextCursor: String
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

    init(client: APIClient) {
        self.client = client
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
}
