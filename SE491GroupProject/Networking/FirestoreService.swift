import Foundation
import FirebaseAuth
import FirebaseFirestore
import TelemetryDeck

class FirestoreService {
    
    let db = Firestore.firestore()
    let userSession: FirebaseAuth.User?
    let favorites = "favorites"
    
    init() {
        self.userSession = Auth.auth().currentUser
    }
    
    // Add User Favorite Restaurant to Firestore
    func addToUserFavRestaurant(_ restaurant: Business) {
        if let userSession = userSession {
            let favCollection = db.collection("users").document(userSession.uid).collection(favorites)
            do {
                try favCollection.document("\(restaurant.name)").setData(from: restaurant)
            } catch let error {
                TelemetryDeck.signal("FirestoreError", parameters: ["error": error.localizedDescription])
                print("Error writing to favorite: \(error)" )
            }
        }
    }
    
    // Fetch User Favorite Restaurants data from Firestore
    func getUserFavRestaurant() async -> [Business] {
        var restaurants: [Business] = []
        do{
            if let userSession = userSession {
                let querySnapshot = try await self.db.collection("users").document(userSession.uid).collection(favorites).getDocuments()
                for document in querySnapshot.documents {
                    let restaurant = try document.data(as: Business.self)
                    restaurants.append(restaurant)
                }
            }
        } catch {
            print("Error getting favorite restaurants from Firebase")
        }
        return restaurants
    }
    
    // Delete User Favorite Restaruant from Firestore
    func deleteUserFavRestaurant(_ name: String) {
        Task {
            do {
                if let userSession = userSession {
                    try await db.collection("users").document(userSession.uid).collection(favorites).document(name).delete()
                }
            } catch {
                print("Error removing Favorite Restaurant")
            }
        }
    }
    
    // Let user make a restaurant request
    func makeRequest(name: String, address: String) {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let formattedDate = dateFormatter.string(from: currentDate)
        
        TelemetryDeck.signal("NewRestaurantRequest", parameters: ["RestaurantName": name.lowercased()])
        
        TelemetryDeck.signal("FeatureUsed", parameters: ["featureName": "Restaurant Request"])
        
        db.collection("Restaurant Requests").document(formattedDate).setData([
            "Restaurant Name": name,
            "Restaurant Address": address
        ])
    }
}
