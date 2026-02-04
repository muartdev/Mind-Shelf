import WidgetKit
import SwiftUI

struct MindShelfWidgetEntry: TimelineEntry {
    let date: Date
    let links: [WidgetLink]
}

struct MindShelfWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MindShelfWidgetEntry {
        MindShelfWidgetEntry(date: Date(), links: SampleData.links)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MindShelfWidgetEntry) -> Void) {
        let links = WidgetLinkStore.loadLinks()
        completion(MindShelfWidgetEntry(date: Date(), links: WidgetLinkStore.pickTopLinks(from: links)))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MindShelfWidgetEntry>) -> Void) {
        let links = WidgetLinkStore.loadLinks()
        let entry = MindShelfWidgetEntry(date: Date(), links: WidgetLinkStore.pickTopLinks(from: links))
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct MindShelfWidgetView: View {
    let entry: MindShelfWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Mind Shelf")
                    .font(.headline)
                Spacer()
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(.secondary)
            }
            
            ForEach(entry.links.prefix(3)) { link in
                if let url = link.deepLinkURL {
                    Link(destination: url) {
                        HStack(spacing: 8) {
                            Image(systemName: link.isFavorite ? "star.fill" : "link")
                                .font(.caption)
                                .foregroundStyle(link.isFavorite ? .yellow : .secondary)
                                .frame(width: 16)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(link.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                Text(link.domain)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(14)
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

@main
struct MindShelfWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MindShelfWidget", provider: MindShelfWidgetProvider()) { entry in
            MindShelfWidgetView(entry: entry)
        }
        .configurationDisplayName("Mind Shelf")
        .description("Quick access to your latest links.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Widget Data

struct WidgetLink: Codable, Identifiable {
    let id: UUID
    let title: String
    let url: String
    let isFavorite: Bool
    let createdDate: Date
    
    var domain: String {
        guard let host = URL(string: url)?.host else { return url }
        return host.replacingOccurrences(of: "www.", with: "")
    }
    
    var deepLinkURL: URL? {
        URL(string: "mindshelf://link/\(id.uuidString)")
    }
}

enum WidgetLinkStore {
    static let suiteName = "group.mindshelf"
    static let linksKey = "widgetLinks"
    
    static func loadLinks() -> [WidgetLink] {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: linksKey),
              let decoded = try? JSONDecoder().decode([WidgetLink].self, from: data) else {
            return []
        }
        return decoded
    }
    
    static func pickTopLinks(from links: [WidgetLink]) -> [WidgetLink] {
        let favorites = links.filter { $0.isFavorite }
        if favorites.count >= 3 {
            return Array(favorites.prefix(3))
        }
        let recent = links.sorted { $0.createdDate > $1.createdDate }
        return Array(recent.prefix(3))
    }
}

enum SampleData {
    static let links: [WidgetLink] = [
        WidgetLink(id: UUID(), title: "SwiftUI Glassmorphism", url: "https://developer.apple.com", isFavorite: true, createdDate: Date()),
        WidgetLink(id: UUID(), title: "Design Notes", url: "https://medium.com", isFavorite: false, createdDate: Date()),
        WidgetLink(id: UUID(), title: "Productivity Tips", url: "https://example.com", isFavorite: false, createdDate: Date())
    ]
}
