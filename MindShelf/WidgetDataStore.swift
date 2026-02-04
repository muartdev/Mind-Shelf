import Foundation
import WidgetKit

struct WidgetLink: Codable, Identifiable {
    let id: UUID
    let title: String
    let url: String
    let isFavorite: Bool
    let createdDate: Date
}

enum WidgetDataStore {
    static let suiteName = "group.mindshelf"
    static let linksKey = "widgetLinks"
    static let maxStoredLinks = 50
    
    static func loadLinks() -> [WidgetLink] {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: linksKey),
              let decoded = try? JSONDecoder().decode([WidgetLink].self, from: data) else {
            return []
        }
        return decoded
    }
    
    static func saveLinks(_ links: [WidgetLink]) {
        let trimmed = Array(links.prefix(maxStoredLinks))
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults(suiteName: suiteName)?.set(data, forKey: linksKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    static func upsert(link: LinkItem) {
        var links = loadLinks()
        let updated = WidgetLink(
            id: link.id,
            title: link.title.isEmpty ? link.url : link.title,
            url: link.url,
            isFavorite: link.isFavorite,
            createdDate: link.createdDate
        )
        links.removeAll { $0.id == link.id }
        links.insert(updated, at: 0)
        links.sort { $0.createdDate > $1.createdDate }
        saveLinks(links)
    }
    
    static func removeLink(id: UUID) {
        var links = loadLinks()
        links.removeAll { $0.id == id }
        saveLinks(links)
    }
    
    static func updateFavorite(id: UUID, isFavorite: Bool) {
        var links = loadLinks()
        if let index = links.firstIndex(where: { $0.id == id }) {
            let link = links[index]
            links[index] = WidgetLink(
                id: link.id,
                title: link.title,
                url: link.url,
                isFavorite: isFavorite,
                createdDate: link.createdDate
            )
            saveLinks(links)
        }
    }
    
    static func sync(from links: [LinkItem]) {
        let mapped = links.map {
            WidgetLink(
                id: $0.id,
                title: $0.title.isEmpty ? $0.url : $0.title,
                url: $0.url,
                isFavorite: $0.isFavorite,
                createdDate: $0.createdDate
            )
        }
        let sorted = mapped.sorted { $0.createdDate > $1.createdDate }
        saveLinks(sorted)
    }
}
