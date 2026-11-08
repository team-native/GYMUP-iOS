import SwiftUI

struct HistoryAlbumView: View {
    let store: HistoryStore
    let onOpenRoutines: () -> Void
    let onOpenDetail: (UUID) -> Void
    let onCompare: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: String?
    @State private var selectedServerPhoto: HistoryServerPhoto?
    @State private var viewModel: HistoryAlbumViewModel
    private let photosDownloadService: PhotosDownloading?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    @MainActor
    init(
        store: HistoryStore,
        photosService: PhotosListing? = nil,
        onOpenRoutines: @escaping () -> Void,
        onOpenDetail: @escaping (UUID) -> Void,
        onCompare: @escaping (UUID) -> Void
    ) {
        self.store = store
        self.onOpenRoutines = onOpenRoutines
        self.onOpenDetail = onOpenDetail
        self.onCompare = onCompare
        photosDownloadService = photosService as? PhotosDownloading
        _viewModel = State(initialValue: HistoryAlbumViewModel(service: photosService))
    }

    var body: some View {
        VStack(spacing: 0) {
            HistoryNavigationBar(
                title: "Progress Album",
                onBack: dismiss.callAsFunction,
                actionTitle: store.records.count < 2 ? nil : "비교",
                action: compareAction
            )
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if albumData.hasRecords {
                        exerciseFilter
                    }
                    if let errorMessage = viewModel.errorMessage {
                        HistoryServerErrorNotice(message: errorMessage) {
                            Task { await viewModel.retry() }
                        }
                    }
                    if viewModel.isLoading && viewModel.serverPhotos.isEmpty {
                        ProgressView()
                            .tint(GymupColors.accent)
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .accessibilityLabel("서버 사진 불러오는 중")
                    }
                    if albumData.months.isEmpty && serverPhotoData.months.isEmpty && !viewModel.isLoading {
                        emptyContent
                    }
                    if !albumData.months.isEmpty {
                        ForEach(albumData.months) { group in
                            monthSection(group)
                        }
                    }
                    if !serverPhotoData.months.isEmpty {
                        serverPhotoSections
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.refresh() }
        .sheet(item: $selectedServerPhoto) { photo in
            HistoryServerPhotoDetailSheet(photo: photo, service: photosDownloadService)
        }
    }

    private var exerciseFilter: some View {
        Menu {
            Button("전체 운동") { selectedExercise = nil }
            ForEach(albumData.exerciseOptions, id: \.self) { exercise in
                Button(exercise) { selectedExercise = exercise }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 13, weight: .semibold))
                Text(selectedExercise ?? "운동 종목")
                    .font(GymupTypography.uiCaption)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(GymupColors.primaryText)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(GymupColors.surface, in: Capsule())
        }
        .accessibilityLabel("운동 종목 필터")
        .accessibilityValue(selectedExercise ?? "전체 운동")
        .accessibilityIdentifier("history.album.exerciseFilter")
    }

    private func monthSection(_ group: HistoryAlbumSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HistorySectionTitle(title: group.title, subtitle: "\(group.records.count)장")
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(group.records) { record in
                    Button {
                        onOpenDetail(record.id)
                    } label: {
                        HistoryAlbumTile(record: record)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(record.albumAccessibilityLabel)
                    .accessibilityHint("운동 사진과 상세 기록 열기")
                    .accessibilityIdentifier("history.album.\(record.id.uuidString)")
                }
            }
        }
    }

    private var albumData: HistoryAlbumData {
        HistoryAlbumData(records: store.records, selectedExercise: selectedExercise)
    }

    private var serverPhotoData: HistoryServerPhotoData {
        HistoryServerPhotoData(photos: viewModel.serverPhotos)
    }

    private var serverPhotoSections: some View {
        VStack(alignment: .leading, spacing: 12) {
            HistorySectionTitle(title: "서버 사진", subtitle: "\(viewModel.serverPhotos.count)장")
            ForEach(serverPhotoData.months) { group in
                VStack(alignment: .leading, spacing: 12) {
                    HistorySectionTitle(title: group.title, subtitle: "\(group.photos.count)장")
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(group.photos) { photo in
                            Button {
                                selectedServerPhoto = photo
                            } label: {
                                HistoryServerPhotoTile(photo: photo)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                "\(HistoryDateText.string(photo.capturedAt, format: "M월 d일")), 서버 운동 사진"
                            )
                            .accessibilityHint("사진 크게 보기")
                            .accessibilityIdentifier("history.album.serverPhoto.\(photo.id)")
                        }
                    }
                }
            }
        }
    }

    private var compareAction: (() -> Void)? {
        guard store.records.count > 1, let record = store.records.first else { return nil }
        return { onCompare(record.id) }
    }

    private var emptyContent: some View {
        let noRecords = !albumData.hasRecords
        return VStack(spacing: 12) {
            Image(systemName: noRecords ? "photo.on.rectangle.angled" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(GymupColors.secondaryText)
                .accessibilityHidden(true)
            Text(noRecords ? "아직 모은 운동 사진이 없어요" : "선택한 운동의 사진이 없어요")
                .font(GymupTypography.uiStrong)
                .foregroundStyle(GymupColors.primaryText)
                .multilineTextAlignment(.center)
            Text(emptyDescription(noRecords: noRecords))
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if noRecords {
                Button(action: onOpenRoutines) {
                    Text("루틴 시작하기")
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background(GymupColors.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("루틴 시작하기")
                .accessibilityIdentifier("history.album.startRoutine")
            } else if selectedExercise != nil {
                Button("전체 운동 보기") { selectedExercise = nil }
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.accent)
                    .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(24)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("history.album.emptyState")
    }

    private func emptyDescription(noRecords: Bool) -> String {
        if noRecords {
            return "운동을 완료하고 사진을 남기면 이곳에서 모아볼 수 있어요."
        }
        return "다른 운동 종목을 선택해 보세요."
    }
}

private struct HistoryAlbumTile: View {
    let record: WorkoutRecord

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                HistoryWorkoutPhoto(assetName: record.photoAssetName)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .accessibilityHidden(true)
                LinearGradient(
                    colors: [.clear, .black.opacity(0.62)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                Text(HistoryDateText.string(record.date, format: "M.d"))
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.46), in: Capsule())
                    .padding(7)
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.76, contentMode: .fit)
    }
}

private struct HistoryServerPhotoTile: View {
    let photo: HistoryServerPhoto

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                photoImage
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .accessibilityHidden(true)
                LinearGradient(
                    colors: [.clear, .black.opacity(0.62)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                Text(HistoryDateText.string(photo.capturedAt, format: "M.d"))
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.46), in: Capsule())
                    .padding(7)
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.76, contentMode: .fit)
    }

    @ViewBuilder
    private var photoImage: some View {
        if let thumbnailURL = photo.thumbnailURL {
            AsyncImage(url: thumbnailURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    fallbackTile
                }
            }
        } else {
            fallbackTile
        }
    }

    private var fallbackTile: some View {
        ZStack {
            GymupColors.surface
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(GymupColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension WorkoutRecord {
    var albumAccessibilityLabel: String {
        let exercises = self.exercises.map(\.name).joined(separator: ", ")
        return "\(HistoryDateText.string(date, format: "M월 d일")), \(routineName), \(exercises) 운동 사진"
    }
}

#Preview {
    HistoryAlbumView(
        store: HistoryStore(records: HistoryListSampleData.records),
        onOpenRoutines: {},
        onOpenDetail: { _ in },
        onCompare: { _ in }
    )
        .preferredColorScheme(.dark)
}
