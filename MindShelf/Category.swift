import Foundation

enum LinkCategory: String, CaseIterable, Codable {
    case video = "Video"
    case article = "Article"
    case shopping = "Shopping"
    case social = "Social"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .video: return "play.rectangle.fill"
        case .article: return "doc.text.fill"
        case .shopping: return "cart.fill"
        case .social: return "person.2.fill"
        case .other: return "folder.fill"
        }
    }
}
