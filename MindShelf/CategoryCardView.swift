import SwiftUI

struct CategoryCardView: View {
    let category: LinkCategoryGroup
    let count: Int
    let previewLinks: [LinkItem]
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 10) {
                Spacer(minLength: 8)
                
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text(category.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer(minLength: 6)
                
                Text("\(count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if !previewLinks.isEmpty {
                previewStack
                    .padding(8)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var previewStack: some View {
        HStack(spacing: -6) {
            ForEach(previewLinks.prefix(3)) { link in
                faviconCircle(for: link)
            }
        }
    }
    
    private func faviconCircle(for link: LinkItem) -> some View {
        ZStack {
            Circle()
                .fill(Color(.secondarySystemBackground))
                .frame(width: 20, height: 20)
            
            if let url = URL(string: link.url),
               let faviconURL = LinkMetadataService.shared.getFaviconURL(for: url) {
                AsyncImage(url: faviconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                    case .failure, .empty:
                        Image(systemName: "link")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    @unknown default:
                        Image(systemName: "link")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Image(systemName: "link")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var iconBackgroundColor: Color {
        switch category {
        case .youtube:
            return Color.red.opacity(0.5)
        case .development:
            return Color.blue.opacity(0.5)
        case .aiTools:
            return Color.purple.opacity(0.5)
        case .shopping:
            return Color.orange.opacity(0.6)
        case .other:
            return Color.gray.opacity(0.5)
        }
    }
}

#Preview {
    CategoryCardView(category: .youtube, count: 12, previewLinks: [])
        .padding()
        .frame(width: 180)
}
