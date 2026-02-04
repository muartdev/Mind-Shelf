import SwiftUI

struct ToastBanner: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
            .padding(.horizontal, 16)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        ToastBanner(message: "Link saved!")
    }
}
