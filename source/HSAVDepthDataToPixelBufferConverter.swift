import AVFoundation

public class HSAVDepthDataToPixelBufferConverter {
  private let size: Size<Int>
  private let pixelFormatType: OSType

  private lazy var pixelBufferPool: CVPixelBufferPool? = {
    createCVPixelBufferPool(size: size, pixelFormatType: pixelFormatType)
  }()

  public init(size: Size<Int>, pixelFormatType: OSType) {
    self.size = size
    self.pixelFormatType = pixelFormatType
  }

  public func convert(depthData: AVDepthData) -> HSPixelBuffer? {
    guard let pool = pixelBufferPool else {
      return nil
    }
    let buffer = HSPixelBuffer(depthData: depthData)
    // TODO:
//    let iterator: HSPixelBufferIterator<Float> = buffer.makeIterator()
//    let bounds = iterator.bounds()
    let bounds: ClosedRange<Float> = 0.25 ... 3.5
    guard let normalizedPixelBuffer = convertDisparityOrDepthPixelBufferToUInt8(
      pixelBuffer: buffer, pixelBufferPool: pool, bounds: bounds
    ) else {
      return nil
    }
    return normalizedPixelBuffer
  }
}
