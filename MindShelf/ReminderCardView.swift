import SwiftUI

struct ReminderCardView: View {
    let link: LinkItem
    let now: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(displayTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
            
            Text(timeText)
                .font(.caption)
                .foregroundStyle(isDue ? .orange : .secondary)
        }
        .padding(10)
        .frame(width: 180, height: 90, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isDue ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if isDue {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .padding(8)
            }
        }
    }
    
    private var isDue: Bool {
        guard let reminderDate = link.reminderDate else { return false }
        return reminderDate <= now
    }
    
    private var timeText: String {
        guard let reminderDate = link.reminderDate else { return "" }
        if reminderDate <= now {
            return "Due now"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let text = formatter.localizedString(for: reminderDate, relativeTo: now)
        return text.prefix(1).uppercased() + text.dropFirst()
    }
    
    private var displayTitle: String {
        let trimmed = link.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == link.url {
            return displayHost
        }
        return trimmed
    }
    
    private var displayHost: String {
        guard let url = URL(string: link.url) else { return link.url }
        return url.host?.replacingOccurrences(of: "www.", with: "") ?? link.url
    }
}

#Preview {
    ReminderCardView(
        link: LinkItem(
            url: "https://developer.apple.com",
            title: "Apple Developer Documentation",
            category: LinkCategory.article.rawValue,
            reminderDate: Date().addingTimeInterval(3600)
        ),
        now: Date()
    )
    .padding()
}
