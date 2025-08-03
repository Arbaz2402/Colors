import Foundation
import Network

class ColorViewModel: ObservableObject {
    @Published var colorCards: [ColorCard] = []
    @Published var isOnline: Bool = false
    @Published var errorMessage: String? = nil

    private let localStore = LocalColorStore()
    private let firebaseSync = FirebaseSyncManager()
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        loadLocalColors()
        setupNetworkMonitor()
    }

    func generateRandomColor() {
        let hex = ColorViewModel.randomHexColor()
        let card = ColorCard(id: UUID(), hexCode: hex, timestamp: Date())
        colorCards.insert(card, at: 0)
        saveLocally()
        if isOnline {
            syncWithFirebase()
        }
    }

    func loadLocalColors() {
        colorCards = localStore.loadColors()
    }

    func saveLocally() {
        localStore.saveColors(colorCards)
    }

    func syncWithFirebase() {
        guard isOnline else { return }
        firebaseSync.syncColors(colorCards) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteColor(_ card: ColorCard) {
        colorCards.removeAll { $0.id == card.id }
        saveLocally()
        if isOnline {
            firebaseSync.deleteColorFromFirebase(card) { [weak self] result in
                switch result {
                case .success:
                    self?.syncWithFirebase()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func setupNetworkMonitor() {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasOffline = !(self?.isOnline ?? false)
                self?.isOnline = path.status == .satisfied
                if self?.isOnline == true {
                    if wasOffline {
                        // Retry pending sync if coming online
                        self?.firebaseSync.retryPendingSync { result in
                            switch result {
                            case .success:
                                self?.errorMessage = nil
                            case .failure(let error):
                                self?.errorMessage = error.localizedDescription
                            }
                        }
                    } else {
                        self?.syncWithFirebase()
                    }
                }
            }
        }
        monitor?.start(queue: queue)
    }

    static func randomHexColor() -> String {
        let r = Int.random(in: 0...255)
        let g = Int.random(in: 0...255)
        let b = Int.random(in: 0...255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
