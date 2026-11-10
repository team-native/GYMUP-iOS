import SwiftUI
import UIKit

struct PendingWorkoutPhotoUpload {
    let imageData: Data
    let response: RequestWorkoutPhotoUploadResponse
    let filterRequest: CreatePhotoFilterRequest
    let stampRequest: CreatePhotoStampRequest

    var expiration: Date {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: response.expiresAt) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: response.expiresAt) ?? .distantPast
    }
}

extension WorkoutPhotoFlowView {
    var canRetryWorkoutPhotoUpload: Bool {
        guard let pendingWorkoutPhotoUpload else { return false }
        return pendingWorkoutPhotoUpload.expiration > .now
    }

    func uploadSavedWorkoutPhoto(_ image: UIImage) {
        guard let workoutId,
              let imageData = image.jpegData(compressionQuality: 0.92) else { return }
#if DEBUG
        let service = DebugOnboardingNetworking.makePhotosService()
#else
        let service: PhotosAPIService? = nil
#endif
        guard let service else {
            selectionError = "사진은 보관함에 저장됐지만 서버 업로드를 사용할 수 없어요."
            return
        }
        guard !isUploadingWorkoutPhoto else { return }
        isUploadingWorkoutPhoto = true

        Task { @MainActor in
            defer { isUploadingWorkoutPhoto = false }

            do {
                let upload = try await service.requestWorkoutPhotoUpload(
                    workoutId: workoutId,
                    request: RequestWorkoutPhotoUploadRequest(
                        fileName: "workout-progress.jpg",
                        contentType: "image/jpeg",
                        size: imageData.count
                    )
                )
                let pendingUpload = PendingWorkoutPhotoUpload(
                    imageData: imageData,
                    response: upload,
                    filterRequest: makePhotoFilterRequest(),
                    stampRequest: makePhotoStampRequest()
                )
                pendingWorkoutPhotoUpload = pendingUpload
                try await service.uploadWorkoutPhoto(imageData, using: upload)
                pendingWorkoutPhotoUpload = nil
                await submitPhotoProcessingJobs(for: pendingUpload, using: service)
            } catch {
                handleWorkoutPhotoUploadFailure(error)
            }
        }
    }

    func retryWorkoutPhotoUpload() {
        guard let pendingWorkoutPhotoUpload,
              pendingWorkoutPhotoUpload.expiration > .now else {
            self.pendingWorkoutPhotoUpload = nil
            selectionError = "서버 업로드 주소가 만료됐어요. "
                + "사진은 보관함에 저장되어 있고 서버 업로드는 종료됐어요."
            return
        }
#if DEBUG
        let service = DebugOnboardingNetworking.makePhotosService()
#else
        let service: PhotosAPIService? = nil
#endif
        guard let service else {
            self.pendingWorkoutPhotoUpload = nil
            selectionError = "서버 업로드를 사용할 수 없어 재시도를 종료했어요."
            return
        }
        guard !isUploadingWorkoutPhoto else { return }
        isUploadingWorkoutPhoto = true

        Task { @MainActor in
            defer { isUploadingWorkoutPhoto = false }

            do {
                try await service.uploadWorkoutPhoto(
                    pendingWorkoutPhotoUpload.imageData,
                    using: pendingWorkoutPhotoUpload.response
                )
                let uploadedPhoto = pendingWorkoutPhotoUpload
                self.pendingWorkoutPhotoUpload = nil
                selectionError = nil
                await submitPhotoProcessingJobs(for: uploadedPhoto, using: service)
            } catch {
                handleWorkoutPhotoUploadFailure(error)
            }
        }
    }

    private func handleWorkoutPhotoUploadFailure(_ error: Error) {
        guard pendingWorkoutPhotoUpload != nil else {
            selectionError = "사진은 보관함에 저장됐지만 서버 업로드를 준비하지 못했어요."
            return
        }

        let storageError = error as? WorkoutPhotoStorageUploadError
        guard canRetryWorkoutPhotoUpload, storageError?.isRetryable != false else {
            pendingWorkoutPhotoUpload = nil
            selectionError = "사진은 보관함에 저장됐지만 서버 업로드 주소가 만료됐거나 사용할 수 없어요."
            return
        }

        selectionError = "사진은 보관함에 저장됐지만 서버 업로드에 실패했어요. "
            + "발급 주소가 유효한 동안 같은 업로드를 다시 시도할 수 있어요."
    }

    private func makePhotoFilterRequest() -> CreatePhotoFilterRequest {
        CreatePhotoFilterRequest(
            preset: editor.filter.apiPreset,
            adjustments: PhotoFilterAdjustments(
                contrast: 1 + editor.adjustments.contrast / 100,
                shadow: 0,
                sharpness: 1 + editor.adjustments.sharpness / 100,
                highlight: 0,
                tone: 0
            )
        )
    }

    private func makePhotoStampRequest() -> CreatePhotoStampRequest {
        CreatePhotoStampRequest(
            layoutId: stamp.style.apiLayoutID,
            fields: ["routine", "duration", "sets", "growth", "xp"]
        )
    }

    private func submitPhotoProcessingJobs(
        for upload: PendingWorkoutPhotoUpload,
        using service: PhotosAPIService
    ) async {
        var didConfirmAllJobs = true
        do {
            let filterJob = try await service.applyFilter(
                photoId: upload.response.photoId,
                request: upload.filterRequest
            )
            guard filterJob.photoId == upload.response.photoId,
                  !filterJob.jobId.isEmpty,
                  filterJob.status == .processing else {
                throw APIClientError.invalidResponse
            }
        } catch {
            didConfirmAllJobs = false
        }

        do {
            let stampJob = try await service.createStamp(
                photoId: upload.response.photoId,
                request: upload.stampRequest
            )
            guard stampJob.photoId == upload.response.photoId,
                  !stampJob.jobId.isEmpty,
                  stampJob.status == .processing else {
                throw APIClientError.invalidResponse
            }
        } catch {
            didConfirmAllJobs = false
        }

        guard didConfirmAllJobs else {
            selectionError = "사진은 서버에 업로드했지만 필터·스탬프 처리 요청 응답을 확인하지 못했어요."
            return
        }
    }
}
