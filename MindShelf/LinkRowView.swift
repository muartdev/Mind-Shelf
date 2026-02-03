import SwiftUI

struct LinkRowView: View {
    let link: LinkItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Favicon / Icon Container
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 48, height: 48)
                
                if let url = URL(string: link.url),
                   let faviconURL = LinkMetadataService.shared.getFaviconURL(for: url) {
                    AsyncImage(url: faviconURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        case .failure:
                            fallbackIcon
                        case .empty:
                            ProgressView()
                                .scaleEffect(0.5)
                        @unknown default:
                            fallbackIcon
                        }
                    }
                } else {
                    fallbackIcon
                }
            }
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(displayHost)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Text(link.createdDate, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Right Indication (optional, kept clean)
             if link.isFavorite {
                 Image(systemName: "star.fill")
                     .font(.caption)
                     .foregroundStyle(.yellow)
             }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
        // No overlay stroke for cleaner look, or very subtle
    }
    
    private var fallbackIcon: some View {
        Image(systemName: LinkCategory(rawValue: link.category)?.icon ?? "link")
            .font(.system(size: 20))
            .foregroundStyle(.gray)
    }
    
    private var displayTitle: String {
        let trimmed = link.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == link.url {
            return displayHost
        }
        return trimmed
    }
    
    private var displayHost: String {
        hostName(from: link.url)
    }
    
    private func hostName(from urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }
        return url.host?.replacingOccurrences(of: "www.", with: "") ?? urlString
    }
    
    private func categoryColor(for category: LinkCategory) -> Color {
        return category.colors.first ?? .blue
    }
}
