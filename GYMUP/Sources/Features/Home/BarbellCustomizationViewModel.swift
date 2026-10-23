import Observation

enum BarbellItemCategory: String, CaseIterable, Identifiable {
    case all = "전체"
    case plate = "원판"
    case bar = "바"
    case collar = "칼라"
    case background = "배경"
    var id: Self { self }
}

enum BarbellItemID {
    case redPlate, blackPlate, olympicBar, goldCollar, chain, neonBackground
}

struct BarbellItem: Identifiable {
    let id: BarbellItemID
    let title: String
    let category: BarbellItemCategory
    let unlockCondition: String?
    var isNew = false
    var isLocked: Bool { unlockCondition != nil }
}

@Observable
@MainActor
final class BarbellCustomizationViewModel {
    var selectedCategory = BarbellItemCategory.all
    private(set) var equippedPlateID = BarbellItemID.redPlate
    private(set) var items = [
        BarbellItem(id: .redPlate, title: "레드 원판", category: .plate, unlockCondition: nil),
        BarbellItem(id: .blackPlate, title: "블랙 원판", category: .plate, unlockCondition: nil, isNew: true),
        BarbellItem(id: .olympicBar, title: "올림픽 바", category: .bar, unlockCondition: "LV.18"),
        BarbellItem(id: .goldCollar, title: "골드 칼라", category: .collar, unlockCondition: "Streak 10주"),
        BarbellItem(id: .chain, title: "체인", category: .bar, unlockCondition: "운동 50회"),
        BarbellItem(id: .neonBackground, title: "네온 짐 배경", category: .background, unlockCondition: "목표 1회 완료")
    ]

    var filteredItems: [BarbellItem] {
        items.filter { selectedCategory == .all || $0.category == selectedCategory }
    }

    var equippedDescription: String {
        let name = items.first { $0.id == equippedPlateID }?.title ?? "레드 원판"
        return "\(name) · 기본 칼라 착용 중"
    }

    func status(for item: BarbellItem) -> String {
        if let condition = item.unlockCondition { return condition }
        if item.id == equippedPlateID { return "착용 중" }
        return item.isNew ? "NEW" : "보유 중"
    }

    @discardableResult
    func equipPlate(_ id: BarbellItemID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }),
              !items[index].isLocked,
              items[index].category == .plate else { return false }
        equippedPlateID = id
        items[index].isNew = false
        return true
    }
}
