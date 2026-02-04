import SwiftUI

struct CategoryCardView: View {
    let category: LinkCategoryGroup
    let count: Int
    let isSelected: Bool
    let isDropTargeted: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(iconBackgroundColor.opacity(0.35))
                    .frame(width: 56, height: 56)
                
                Image(systemName: category.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(iconBackgroundColor)
            }
            
            Text(category.title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("\(count) items")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(isSelected ? 0.12 : 0.04))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    isDropTargeted ? Color.primary.opacity(0.35) : Color.white.opacity(isSelected ? 0.22 : 0.08),
                    lineWidth: isSelected || isDropTargeted ? 2 : 1
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isDropTargeted)
    }
    
    private var iconBackgroundColor: Color {
        switch category {
        case .youtube:
            return Color.red
        case .development:
            return Color.blue
        case .aiTools:
            return Color.purple
        case .shopping:
            return Color.orange
        case .other:
            return Color.gray
        }
    }
}

#Preview {
    CategoryCardView(category: .youtube, count: 12, isSelected: true, isDropTargeted: false)
        .padding()
}
