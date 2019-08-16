import AVFoundation

public class HSAVDepthDataToPixelBufferConverter {
  private let size: Size<Int>
  private let inputPixelFormatType: OSType
  private let outputPixelFormatType: OSType
  private let bounds: ClosedRange<Float>

  private lazy var pixelBufferPool: CVPixelBufferPool? = {
    createCVPixelBufferPool(size: size, pixelFormatType: outputPixelFormatType)
  }()

  public init(
    size: Size<Int>,
    input inputPixelFormatType: OSType,
    output outputPixelFormatType: OSType,
    bounds: ClosedRange<Float> = 0.5 ... 3.0
  ) {
    self.size = size
    self.inputPixelFormatType = inputPixelFormatType
    self.outputPixelFormatType = outputPixelFormatType
    self.bounds = bounds
  }

  public func convert(depthData: AVDepthData) -> HSPixelBuffer? {
    guard let pool = pixelBufferPool else {
      return nil
    }
    let isCorrectInputFormatType = depthData.depthDataType == inputPixelFormatType
    let convertedDepthData = !isCorrectInputFormatType
      ? depthData.converting(toDepthDataType: inputPixelFormatType)
      : depthData
    let buffer = HSPixelBuffer(depthData: convertedDepthData)
    guard let normalizedPixelBuffer = convertDisparityOrDepthPixelBufferToUInt8(
      pixelBuffer: buffer, pixelBufferPool: pool, bounds: bounds
    ) else {
      return nil
    }
    return normalizedPixelBuffer
  }
}
