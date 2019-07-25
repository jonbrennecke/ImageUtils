import AVFoundation

public struct HSVideoFrameBuffer {
  public let pixelBuffer: HSPixelBuffer
  public let presentationTime: CMTime

  public var size: Size<Int> {
    return pixelBuffer.size
  }

  public init(pixelBuffer: HSPixelBuffer, presentationTime: CMTime) {
    self.pixelBuffer = pixelBuffer
    self.presentationTime = presentationTime
  }
}
