import CoreGraphics

struct HSImageBuffer<T: Numeric> {
    typealias PixelValueType = T
    
    private let pixelBuffer: HSPixelBuffer<T>
    
    public var size: Size<Int> {
        return pixelBuffer.size
    }
    
    init(pixelBuffer: HSPixelBuffer<T>) {
        self.pixelBuffer = pixelBuffer
    }
    
    public func makeImage() -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var bytes = pixelBuffer.getBytes()
        let bytesPerPixel = MemoryLayout<T>.size
        let bitsPerComponent = MemoryLayout<T>.size * 8
        let bitsPerPixel = bytesPerPixel * 8
        let bytesPerRow = bytesPerPixel * size.width
        //    let totalBytes = bytes.count
        let totalBytes = size.height * bytesPerRow
        return withUnsafePointer(to: &bytes) { ptr -> CGImage? in
            let data = UnsafeRawPointer(ptr.pointee).assumingMemoryBound(to: T.self)
            let releaseData: CGDataProviderReleaseDataCallback = {
                (_: UnsafeMutableRawPointer?, _: UnsafeRawPointer, _: Int) -> Void in
            }
            guard let provider = CGDataProvider(dataInfo: nil, data: data, size: totalBytes, releaseData: releaseData) else {
                return nil
            }
            return CGImage(
                width: size.width,
                height: size.height,
                bitsPerComponent: bitsPerComponent,
                bitsPerPixel: bitsPerPixel,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        }
    }
    
    private var bitmapInfo: CGBitmapInfo {
        switch MemoryLayout<T>.size {
        case 4:
            return CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
                .union(.floatComponents)
                .union(.byteOrder32Little)
        case 1:
            fallthrough
        default:
            return CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        }
    }
}
