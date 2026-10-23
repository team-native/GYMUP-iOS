import SwiftUI

struct BarbellCustomizationView: View {
    @Bindable var viewModel: BarbellCustomizationViewModel
    let onNavigationStateChanged: (Bool) -> Void
    var onOpenNewItem: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

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
    }

    private var equipmentPreview: some View {
        VStack(spacing: 4) {
            Image("H5Equipment")
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

    private var inventory: some View {
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
