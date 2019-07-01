import CoreVideo
import UIKit

internal func withLockedBaseAddress<T>(
    _ buffer: CVPixelBuffer,
    flags: CVPixelBufferLockFlags = .readOnly,
    _ callback: (CVPixelBuffer) -> T
    ) -> T {
    CVPixelBufferLockBaseAddress(buffer, flags)
    let ret = callback(buffer)
    CVPixelBufferUnlockBaseAddress(buffer, flags)
    return ret
}

internal func pixelSizeOf<T: Numeric>(buffer: CVPixelBuffer) -> Size<T> {
    return withLockedBaseAddress(buffer) { buffer in
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        return Size<T>(width: T(exactly: width)!, height: T(exactly: height)!)
    }
}

// From https://gist.github.com/cieslak/743f9321834c5a40597afa1634a48343
internal func createBuffer(with image: UIImage) -> CVPixelBuffer? {
    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
    guard status == kCVReturnSuccess else {
        return nil
    }
    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    context?.translateBy(x: 0, y: image.size.height)
    context?.scaleBy(x: 1.0, y: -1.0)
    UIGraphicsPushContext(context!)
    image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    UIGraphicsPopContext()
    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    return pixelBuffer
}

enum BufferType {
    case depthFloat32
    case argbFloat32
    case grayScaleUInt8
    
    public var pixelFormat: OSType {
        switch self {
        case .depthFloat32:
            return kCVPixelFormatType_DepthFloat32
        case .argbFloat32:
            return kCVPixelFormatType_32ARGB
        case .grayScaleUInt8:
            return kCVPixelFormatType_OneComponent8
        }
    }
    
    public var bytesPerPixel: Int {
        switch self {
        case .depthFloat32:
            return MemoryLayout<Float32>.size
        case .argbFloat32:
            return MemoryLayout<Float32>.size
        case .grayScaleUInt8:
            return MemoryLayout<UInt8>.size
        }
    }
}

internal func createBuffer<T>(
    with pixelValues: inout [T], size: Size<Int>, bufferType: BufferType
    ) -> CVPixelBuffer? {
    let attrs = [
        kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
        kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
        ] as CFDictionary
    var buffer: CVPixelBuffer!
    let releaseCallback: CVPixelBufferReleaseBytesCallback? = {
        (_: UnsafeMutableRawPointer?, _: UnsafeRawPointer?) -> Void in
    }
    let status = CVPixelBufferCreateWithBytes(
        kCFAllocatorDefault,
        size.width,
        size.height,
        bufferType.pixelFormat,
        &pixelValues,
        bufferType.bytesPerPixel * size.width,
        releaseCallback,
        nil,
        attrs,
        &buffer
    )
    guard status == kCVReturnSuccess else {
        return nil
    }
    return buffer
}
