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
    var durationText: String?
    var userNote: String?
    var reminderDate: Date?
    
    init(url: String, title: String, category: String, isFavorite: Bool = false, userNote: String? = nil, reminderDate: Date? = nil, durationText: String? = nil) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.category = category
        self.isFavorite = isFavorite
        self.createdDate = Date()
        self.thumbnailURL = nil
        self.durationText = durationText
        self.userNote = userNote
        self.reminderDate = reminderDate
    }
}
