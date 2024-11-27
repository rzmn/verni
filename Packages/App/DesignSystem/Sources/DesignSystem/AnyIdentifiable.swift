import SwiftUI

struct AnyIdentifiable<T>: Identifiable {
    let value: T
    let id: String
    
    init(value: T, id: String = UUID().uuidString) {
        self.value = value
        self.id = id
    }
}
