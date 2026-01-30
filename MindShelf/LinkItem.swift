import Foundation
import SwiftData

@Model
class LinkItem {
    var id: UUID
    var url: String
    var title: String
    var category: String
    var isFavorite: Bool
    var createdDate: Date
    var thumbnailURL: String?
    
    init(url: String, title: String, category: String, isFavorite: Bool = false) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.category = category
        self.isFavorite = isFavorite
        self.createdDate = Date()
        self.thumbnailURL = nil
    }
}
