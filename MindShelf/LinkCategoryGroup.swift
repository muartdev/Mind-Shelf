import Foundation

enum LinkCategoryGroup: String, CaseIterable, Identifiable {
    case youtube
    case development
    case aiTools
    case shopping
    case other
    
    var id: String { rawValue }
    
    static var displayOrder: [LinkCategoryGroup] {
        [.youtube, .development, .aiTools, .shopping, .other]
    }
    
    var title: String {
        switch self {
        case .youtube: return "YouTube"
        case .development: return "Development"
        case .aiTools: return "AI Tools"
        case .shopping: return "Shopping"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .development: return "hammer.fill"
        case .aiTools: return "sparkles"
        case .shopping: return "cart.fill"
        case .other: return "folder.fill"
        }
    }
    
    func matches(_ link: LinkItem) -> Bool {
        switch self {
        case .youtube:
            return isYouTube(link.url)
        case .development:
            return isDevelopment(link.url)
        case .aiTools:
            return isAITools(link.url)
        case .shopping:
            return link.category == LinkCategory.shopping.rawValue || isShopping(link.url)
        case .other:
            return !LinkCategoryGroup.primaryCases.contains { $0.matches(link) }
        }
    }
    
    private static var primaryCases: [LinkCategoryGroup] {
        [.youtube, .development, .aiTools, .shopping]
    }
    
    private func isYouTube(_ urlString: String) -> Bool {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return false }
        return host.contains("youtube.com") || host.contains("youtu.be") || host.contains("music.youtube.com")
    }
    
    private func isDevelopment(_ urlString: String) -> Bool {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return false }
        let devHosts = [
            "developer.apple.com",
            "github.com",
            "gitlab.com",
            "bitbucket.org",
            "stackoverflow.com",
            "stackexchange.com",
            "docs.swift.org",
            "docs.python.org",
            "docs.rs",
            "npmjs.com",
            "developer.android.com",
            "dev.to",
            "hashnode.com",
            "medium.com"
        ]
        return devHosts.contains(where: { host.contains($0) })
    }
    
    private func isAITools(_ urlString: String) -> Bool {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return false }
        let aiHosts = [
            "openai.com",
            "chat.openai.com",
            "anthropic.com",
            "claude.ai",
            "huggingface.co",
            "replicate.com",
            "cohere.com",
            "perplexity.ai",
            "midjourney.com",
            "runwayml.com",
            "stability.ai",
            "groq.com",
            "mistral.ai"
        ]
        return aiHosts.contains(where: { host.contains($0) })
    }
    
    private func isShopping(_ urlString: String) -> Bool {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return false }
        let shoppingHosts = [
            "amazon",
            "ebay",
            "etsy",
            "shopify",
            "aliexpress",
            "temu",
            "walmart",
            "bestbuy",
            "target",
            "ikea",
            "trendyol",
            "hepsiburada",
            "n11"
        ]
        return shoppingHosts.contains(where: { host.contains($0) })
    }
}
