import Observation

@Observable
@MainActor
final class HomeViewModel {
    var name = ""
    private(set) var hasStarted = false

    var greeting: String {
        guard !name.isEmpty else { return "디자인 시스템 기본 구성이 준비되었습니다." }
        return "안녕하세요, \(name)님."
    }

    func start() {
        hasStarted = true
    }
}
