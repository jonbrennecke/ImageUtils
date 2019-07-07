import AVFoundation

public struct HSImageBuffer {
  private let pixelBuffer: HSPixelBuffer

  public var size: Size<Int> {
    return pixelBuffer.size
  }

  public init(pixelBuffer: HSPixelBuffer) {
    self.pixelBuffer = pixelBuffer
  }

  public func makeImage() -> CGImage? {
    let bufferInfo = pixelBuffer.bufferInfo
    let bytesPerRow = pixelBuffer.bytesPerRow
    let totalBytes = size.height * pixelBuffer.bytesPerRow
    return pixelBuffer.withDataPointer { ptr -> CGImage? in
      let releaseData: CGDataProviderReleaseDataCallback = {
        (_: UnsafeMutableRawPointer?, _: UnsafeRawPointer, _: Int) -> Void in
      }
      guard let provider = CGDataProvider(
        dataInfo: nil,
        data: ptr,
        size: totalBytes,
        releaseData: releaseData
      ) else {
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
