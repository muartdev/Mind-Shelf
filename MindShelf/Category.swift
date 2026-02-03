import Foundation
import SwiftUI

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
    
    var colors: [Color] {
        switch self {
        case .video: return [Color.red.opacity(0.15), Color.orange.opacity(0.15)]
        case .article: return [Color.blue.opacity(0.15), Color.cyan.opacity(0.15)]
        case .shopping: return [Color.green.opacity(0.15), Color.mint.opacity(0.15)]
        case .social: return [Color.purple.opacity(0.15), Color.pink.opacity(0.15)]
        case .other: return [Color.gray.opacity(0.15), Color.gray.opacity(0.1)]
        }
    }
    
    var accentColor: Color {
         switch self {
         case .video: return .red
         case .article: return .blue
         case .shopping: return .green
         case .social: return .purple
         case .other: return .gray
         }
    }
}
