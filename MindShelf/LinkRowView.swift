import SwiftUI

struct LinkRowView: View {
    let link: LinkItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon - daha büyük ve renkli
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: categoryColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: categoryColors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
            
            // Link info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(link.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if link.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.yellow)
                    }
                }
                
                Text(link.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(link.createdDate, style: .relative)
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var categoryIcon: String {
        guard let category = LinkCategory(rawValue: link.category) else {
            return "folder.fill"
        }
        return category.icon
    }
    
    private var categoryColors: [Color] {
        guard let category = LinkCategory(rawValue: link.category) else {
            return [.gray, .gray.opacity(0.7)]
        }
        
        switch category {
        case .video:
            return [.red, .orange]
        case .article:
            return [.blue, .cyan]
        case .shopping:
            return [.green, .mint]
        case .social:
            return [.purple, .pink]
        case .other:
            return [.gray, .gray.opacity(0.7)]
        }
    }
}