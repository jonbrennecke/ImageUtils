import AVFoundation

public struct HSImageBuffer<T: Numeric> {
  typealias PixelValueType = T

  private let pixelBuffer: HSPixelBuffer<T>

  public var size: Size<Int> {
    return pixelBuffer.size
  }

  public init(pixelBuffer: HSPixelBuffer<T>) {
    self.pixelBuffer = pixelBuffer
  }

  public func makeImage() -> CGImage? {
    let bufferInfo = pixelBuffer.bufferInfo
    let bytesPerRow = pixelBuffer.bytesPerRow
    let totalBytes = size.height * pixelBuffer.bytesPerRow
    return pixelBuffer.withUnsafeRawPointer { ptr -> CGImage? in
      let releaseData: CGDataProviderReleaseDataCallback = {
        (_: UnsafeMutableRawPointer?, _: UnsafeRawPointer, _: Int) -> Void in
      }
      guard let provider = CGDataProvider(dataInfo: nil, data: ptr, size: totalBytes, releaseData: releaseData) else {
        return nil
      }
      return CGImage(
        width: size.width,
        height: size.height,
        bitsPerComponent: bufferInfo.bitsPerComponent,
        bitsPerPixel: bufferInfo.bitsPerPixel,
        bytesPerRow: bytesPerRow,
        space: bufferInfo.colorSpace,
        bitmapInfo: bufferInfo.bitmapInfo,
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
      )
    }
  }
}
