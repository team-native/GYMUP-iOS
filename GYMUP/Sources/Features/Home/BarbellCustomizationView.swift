import SwiftUI

struct BarbellCustomizationView: View {
    @Bindable var viewModel: BarbellCustomizationViewModel
    @Bindable private var avatarViewModel: AvatarAPIViewModel
    let onNavigationStateChanged: (Bool) -> Void
    var onOpenNewItem: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @MainActor
    init(
        viewModel: BarbellCustomizationViewModel,
        avatarViewModel: AvatarAPIViewModel? = nil,
        onNavigationStateChanged: @escaping (Bool) -> Void,
        onOpenNewItem: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        _avatarViewModel = Bindable(wrappedValue: avatarViewModel ?? AvatarAPIViewModel(service: nil))
        self.onNavigationStateChanged = onNavigationStateChanged
        self.onOpenNewItem = onOpenNewItem
    }

    var body: some View {
        VStack(spacing: 0) {
            GymupDetailNavigationBar(title: "바벨 꾸미기", onBack: dismiss.callAsFunction)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    equipmentPreview
                        .padding(.bottom, -5)
                    categories
                        .padding(.bottom, 22)
                    inventory
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { onNavigationStateChanged(true) }
        .onDisappear { onNavigationStateChanged(false) }
        .task { await avatarViewModel.loadItems() }
    }

    private var equipmentPreview: some View {
        VStack(spacing: 4) {
            Image(viewModel.previewAssetName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320)
                .frame(height: 160)
            Text(viewModel.equippedDescription)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .frame(minHeight: 15)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var categories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BarbellItemCategory.allCases) { category in
                    GymupFilterChip(title: category.rawValue, isSelected: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var inventory: some View {
        if avatarViewModel.isAvailable {
            if avatarViewModel.isLoadingItems {
                HStack(spacing: GymupSpacing.small) {
                    ProgressView().controlSize(.small).tint(GymupColors.accent)
                    Text("서버 아이템을 불러오고 있어요.")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            } else if let errorMessage = avatarViewModel.itemsErrorMessage {
                VStack(alignment: .leading, spacing: GymupSpacing.small) {
                    Text(errorMessage)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                    Button("다시 시도") { Task { await avatarViewModel.loadItems() } }
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.accent)
                        .disabled(avatarViewModel.isLoadingItems)
                }
                .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                .accessibilityIdentifier("home.avatar.items.error")
            } else if let response = avatarViewModel.items, response.items.isEmpty {
                GymupEmptyState(
                    symbol: "shippingbox",
                    title: "보유 아이템이 없어요",
                    message: "보상으로 받은 바벨 아이템이 여기에 표시돼요."
                )
                .accessibilityIdentifier("home.avatar.items.empty")
            } else if let response = avatarViewModel.items {
                Text("서버에서 아이템 \(response.items.count)개를 불러왔어요. 아이템 정보 형식이 앱 화면에 연결되지 않았어요.")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("home.avatar.items.unsupported")
            } else {
                ProgressView().tint(GymupColors.accent).frame(maxWidth: .infinity, minHeight: 88)
            }
        } else {
            localInventory
        }
    }

    private var localInventory: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(viewModel.filteredItems) { item in
                if item.isNew {
                    if let onOpenNewItem {
                        Button(action: onOpenNewItem) {
                            itemTile(item)
                        }
                        .buttonStyle(.plain)
                    } else {
                        itemTile(item)
                    }
                } else if !item.isLocked && item.id != viewModel.equippedPlateID {
                    Button {
                        viewModel.equipPlate(item.id)
                    } label: {
                        itemTile(item)
                    }
                    .buttonStyle(.plain)
                } else {
                    itemTile(item)
                }
            }
        }
    }

    private func itemTile(_ item: BarbellItem) -> some View {
        let isEquipped = item.id == viewModel.equippedPlateID
        return VStack(spacing: 8) {
            Image(item.isLocked ? "H5IconLock" : "H5IconTarget")
                .resizable()
                .frame(width: item.isLocked ? 16.4 : 21.32, height: item.isLocked ? 16.4 : 21.32)
                .frame(width: 45.92, height: 45.92)
                .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 11.48))
            Text(item.title)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(item.isLocked ? GymupColors.secondaryText : GymupColors.primaryText)
                .frame(height: 15)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(viewModel.status(for: item))
                .font(GymupTypography.label)
                .foregroundStyle(item.isNew && !isEquipped ? GymupColors.brandText : GymupColors.tertiaryText)
                .textCase(.uppercase)
                .frame(height: 13)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isEquipped ? GymupColors.brandSubtle : GymupColors.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isEquipped ? GymupColors.accent : (item.isNew ? GymupColors.strongBorder : .clear), lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.isLocked ? "잠김, " : "")\(viewModel.status(for: item))")
    }
}

#Preview {
    NavigationStack {
        BarbellCustomizationView(viewModel: BarbellCustomizationViewModel(), onNavigationStateChanged: { _ in })
    }
    .preferredColorScheme(.dark)
}
