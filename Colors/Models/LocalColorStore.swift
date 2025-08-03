import Foundation

class LocalColorStore {
    private let key = "saved_colors"

    func saveColors(_ colors: [ColorCard]) {
        if let data = try? JSONEncoder().encode(colors) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadColors() -> [ColorCard] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let colors = try? JSONDecoder().decode([ColorCard].self, from: data) else {
            return []
        }
        return colors
    }
}
