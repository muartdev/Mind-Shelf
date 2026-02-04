import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeSheetView: View {
    let urlString: String
    let title: String
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                qrImage
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                Text(urlString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var qrImage: Image {
        let data = Data(urlString.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        guard let output = filter.outputImage else {
            return Image(systemName: "qrcode")
        }
        
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
            return Image(decorative: cgImage, scale: 1, orientation: .up)
        }
        return Image(systemName: "qrcode")
    }
}

#Preview {
    QRCodeSheetView(urlString: "https://developer.apple.com", title: "Apple Developer Documentation")
}
