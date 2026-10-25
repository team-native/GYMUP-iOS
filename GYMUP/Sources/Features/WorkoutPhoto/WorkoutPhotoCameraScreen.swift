import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct WorkoutPhotoCameraScreen: View {
    @ObservedObject var camera: WorkoutPhotoCameraController
    @Binding var filter: WorkoutPhotoFilter
    @Binding var selectedItem: PhotosPickerItem?

    let onClose: () -> Void
    let onCapture: (UIImage?) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            WorkoutPhotoCameraPreview(
                session: camera.session,
                isMirrored: camera.cameraPosition == .front
            )
            .saturation(filter.saturation)
            .contrast(filter.contrast)
            .brightness(filter.brightness)
            .overlay {
                Rectangle()
                    .fill(filter.overlayColor)
                    .blendMode(.softLight)
                    .accessibilityHidden(true)
            }
            .scaleEffect(x: filter == .mirror ? -1 : 1, y: 1)
            .ignoresSafeArea()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("라이브 카메라 미리보기, \(filter.rawValue) 필터")

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.42), location: 0),
                    .init(color: .clear, location: 0.28),
                    .init(color: .clear, location: 0.62),
                    .init(color: .black.opacity(0.78), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                topControls
                    .padding(.top, 4)

                Spacer(minLength: 20)

                filterSelector
                    .padding(.bottom, 18)

                captureControls
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.black)
        .onAppear(perform: camera.start)
        .onDisappear(perform: camera.stop)
        .alert("카메라", isPresented: isShowingCameraError) {
            Button("확인", role: .cancel, action: camera.dismissError)
        } message: {
            Text(camera.errorMessage ?? "")
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .accessibilityIdentifier("workout.photo.camera")
    }

    private var topControls: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.35), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(camera.isCapturing)
            .accessibilityLabel("카메라 닫기")
            .accessibilityHint("사진 촬영을 닫고 운동 흐름으로 돌아갑니다.")
            .accessibilityIdentifier("workout.photo.camera.close")

            Spacer(minLength: 8)

            Text(filter.rawValue.uppercased())
                .font(Font.custom("Archivo-SemiBold", size: 10, relativeTo: .caption))
                .tracking(0.7)
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .frame(minHeight: 28)
                .background(WorkoutCompletionColors.red, in: Capsule())
                .accessibilityLabel("선택된 필터, \(filter.rawValue)")
                .accessibilityIdentifier("workout.photo.camera.selected-filter")

            Spacer(minLength: 8)

            Button(action: camera.toggleFlash) {
                Image(systemName: camera.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(camera.canUseFlash ? .white : .white.opacity(0.45))
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.35), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!camera.canUseFlash || camera.isCapturing)
            .accessibilityLabel(camera.isFlashOn ? "플래시 끄기" : "플래시 켜기")
            .accessibilityHint(
                camera.canUseFlash
                    ? "카메라 플래시 설정을 변경합니다."
                    : "현재 카메라에서는 플래시를 사용할 수 없습니다."
            )
            .accessibilityIdentifier("workout.photo.camera.flash")
        }
    }

    private var filterSelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 2) {
                ForEach(WorkoutPhotoFilter.allCases) { option in
                    Button {
                        filter = option
                    } label: {
                        Text(option.rawValue)
                            .font(Font.custom("GothicA1-Medium", size: 10, relativeTo: .caption))
                            .foregroundStyle(filter == option ? .white : .white.opacity(0.76))
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .frame(minHeight: 44)
                            .background {
                                if filter == option {
                                    Capsule().fill(WorkoutCompletionColors.red)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == option ? .isSelected : [])
                    .accessibilityIdentifier("workout.photo.camera.filter.\(option.id.rawValue.lowercased())")
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(.black.opacity(0.42), in: Capsule())
        .accessibilityIdentifier("workout.photo.camera.filters")
    }

    private var captureControls: some View {
        HStack(alignment: .center) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 12))
                    .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("사진 보관함 열기")
            .accessibilityHint("사진 보관함에서 운동 사진을 선택합니다.")
            .disabled(camera.isCapturing)
            .accessibilityIdentifier("workout.photo.camera.gallery")

            Spacer(minLength: 0)

            Button {
                camera.capturePhoto(onCaptured: onCapture)
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2)
                        .frame(width: 76, height: 76)
                    Circle()
                        .fill(WorkoutCompletionColors.red)
                        .frame(width: 62, height: 62)
                }
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(camera.isCapturing || !camera.isRunning)
            .accessibilityLabel(camera.isCapturing ? "사진 촬영 중" : "사진 촬영")
            .accessibilityHint("현재 화면을 촬영하고 사진 보정 화면으로 이동합니다.")
            .accessibilityIdentifier("workout.photo.camera.capture")

            Spacer(minLength: 0)

            Button(action: camera.switchCamera) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(.black.opacity(0.42), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(camera.isCapturing || !camera.isRunning)
            .accessibilityLabel("전면과 후면 카메라 전환")
            .accessibilityIdentifier("workout.photo.camera.switch")
        }
    }

    private var isShowingCameraError: Binding<Bool> {
        Binding(
            get: { camera.errorMessage != nil },
            set: { isPresented in
                if !isPresented { camera.dismissError() }
            }
        )
    }
}

private struct WorkoutPhotoCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let isMirrored: Bool

    func makeUIView(context: Context) -> WorkoutPhotoCameraPreviewView {
        let view = WorkoutPhotoCameraPreviewView()
        guard let previewLayer = view.previewLayer else {
            assertionFailure("카메라 미리보기 레이어를 만들지 못했어요.")
            return view
        }
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        updateMirroring(on: previewLayer)
        return view
    }

    func updateUIView(_ view: WorkoutPhotoCameraPreviewView, context: Context) {
        guard let previewLayer = view.previewLayer else { return }
        if previewLayer.session !== session {
            previewLayer.session = session
        }
        updateMirroring(on: previewLayer)
    }

    private func updateMirroring(on previewLayer: AVCaptureVideoPreviewLayer) {
        guard let connection = previewLayer.connection else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        guard connection.isVideoMirroringSupported else { return }
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = isMirrored
    }
}

private final class WorkoutPhotoCameraPreviewView: UIView {
    override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer? {
        layer as? AVCaptureVideoPreviewLayer
    }
}
