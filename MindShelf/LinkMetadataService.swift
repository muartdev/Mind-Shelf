import Foundation
import LinkPresentation
import UIKit

class LinkMetadataService {
    static let shared = LinkMetadataService()
    
    private init() {}
    
    func fetchMetadata(for url: URL) async throws -> (title: String, imageURL: String?) {
        let provider = LPMetadataProvider()
        let metadata = try await provider.startFetchingMetadata(for: url)
        
        let title = metadata.title ?? url.absoluteString
        
        return (title, nil)
    }
}
