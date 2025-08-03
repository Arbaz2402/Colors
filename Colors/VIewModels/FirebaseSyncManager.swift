import Foundation
import FirebaseCore
import FirebaseFirestore

class FirebaseSyncManager {
    private let pendingKey = "pending_sync_colors"
    private let db = Firestore.firestore()
    
    // Call this to sync colors to Firestore
    func syncColors(_ colors: [ColorCard], completion: @escaping (Result<Void, Error>) -> Void) {
        // If no internet, save to pending
        guard isOnline() else {
            savePending(colors)
            completion(.failure(NSError(domain: "No Internet", code: -1009)))
            return
        }
        
        let batch = db.batch()
        let collection = db.collection("colorCards")
        for card in colors {
            let ref = collection.document(card.id.uuidString)
            batch.setData([
                "hexCode": card.hexCode,
                "timestamp": card.timestamp
            ], forDocument: ref)
        }
        batch.commit { error in
            if let error = error {
                self.savePending(colors)
                completion(.failure(error))
            } else {
                self.clearPending()
                completion(.success(()))
            }
        }
    }
    
    // Call this when network is restored
    func retryPendingSync(completion: @escaping (Result<Void, Error>) -> Void) {
        let pending = loadPending()
        guard !pending.isEmpty else { completion(.success(())); return }
        syncColors(pending, completion: completion)
    }
    
    // MARK: - Pending sync helpers
    private func savePending(_ colors: [ColorCard]) {
        if let data = try? JSONEncoder().encode(colors) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
    }
    private func loadPending() -> [ColorCard] {
        guard let data = UserDefaults.standard.data(forKey: pendingKey),
              let colors = try? JSONDecoder().decode([ColorCard].self, from: data) else {
            return []
        }
        return colors
    }
    private func clearPending() {
        UserDefaults.standard.removeObject(forKey: pendingKey)
    }
    private func isOnline() -> Bool {
        // You may want to use NWPathMonitor or other real check
        return true // Placeholder: always online for now
    }
    
    // Delete a color card from Firestore
    func deleteColorFromFirebase(_ card: ColorCard, completion: ((Result<Void, Error>) -> Void)? = nil) {
        let ref = db.collection("colorCards").document(card.id.uuidString)
        ref.delete { error in
            if let error = error {
                completion?(.failure(error))
            } else {
                completion?(.success(()))
            }
        }
    }
}
