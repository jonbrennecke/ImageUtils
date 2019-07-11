import Accelerate
import AVFoundation


public func convertBGRAPixelBufferToGrayscale(pixelBuffer: HSPixelBuffer, pixelBufferPool: CVPixelBufferPool) -> HSPixelBuffer? {
  return pixelBuffer.withMutableDataPointer({ ptr -> HSPixelBuffer? in
    var sourceBuffer = vImage_Buffer(
      data: ptr,
      height: vImagePixelCount(pixelBuffer.size.height),
      width: vImagePixelCount(pixelBuffer.size.width),
      rowBytes: pixelBuffer.bytesPerRow
    )
    let destinationBufferInfo = HSBufferInfo(pixelFormatType: kCVPixelFormatType_OneComponent8)
    let destinationBytesPerRow = pixelBuffer.size.width * destinationBufferInfo.bytesPerPixel
    let destinationTotalBytes = pixelBuffer.size.height * destinationBytesPerRow
    
    var destinationBuffer = vImage_Buffer()
    let initError = vImageBuffer_Init(
      &destinationBuffer,
      vImagePixelCount(pixelBuffer.size.height),
      vImagePixelCount(pixelBuffer.size.width),
      UInt32(destinationBufferInfo.bitsPerPixel),
      vImage_Flags(kvImageNoFlags)
    )
    if initError != kvImageNoError {
      return nil
    }
    defer {
      free(destinationBuffer.data)
    }
    
    let redCoeff = Float(0.2126)
    let greenCoeff = Float(0.7152)
    let blueCoeff = Float(0.0722)
    let divisor = Int32(0x1000)
    var coefficientsMatrix = [
      Int16(redCoeff * Float(divisor)),
      Int16(greenCoeff * Float(divisor)),
      Int16(blueCoeff * Float(divisor))
    ]
    var preBias: [Int16] = [0, 0, 0, 0]
    let postBias = Int32(0)
    
    let error = vImageMatrixMultiply_ARGB8888ToPlanar8(
      &sourceBuffer,
      &destinationBuffer,
      &coefficientsMatrix,
      0x1000,
      &preBias,
      postBias,
      vImage_Flags(kvImageNoFlags)
    )
    if error != kvImageNoError {
      return nil
    }
    guard var destinationPixelBuffer = createPixelBuffer(with: pixelBufferPool) else {
      return nil
    }
    guard case .some = copy(
      buffer: &destinationBuffer,
      to: &destinationPixelBuffer,
      bufferInfo: destinationBufferInfo
      ) else {
        return nil
    }
    return HSPixelBuffer(pixelBuffer: destinationPixelBuffer)
  })
}

public func convertDisparityFloat32PixelBufferToUInt8(
  pixelBuffer: HSPixelBuffer, pixelBufferPool: CVPixelBufferPool
) -> HSPixelBuffer? {
  return pixelBuffer.withMutableDataPointer({ ptr -> HSPixelBuffer? in
    var sourceBuffer = vImage_Buffer(
      data: ptr,
      height: vImagePixelCount(pixelBuffer.size.height),
      width: vImagePixelCount(pixelBuffer.size.width),
      rowBytes: pixelBuffer.bytesPerRow
    )
    let destinationBufferInfo = HSBufferInfo(pixelFormatType: kCVPixelFormatType_OneComponent8)
    let destinationBytesPerRow = pixelBuffer.size.width * destinationBufferInfo.bytesPerPixel
    let destinationTotalBytes = pixelBuffer.size.height * destinationBytesPerRow
    
    var destinationBuffer = vImage_Buffer()
    let initError = vImageBuffer_Init(
      &destinationBuffer,
      vImagePixelCount(pixelBuffer.size.height),
      vImagePixelCount(pixelBuffer.size.width),
      UInt32(destinationBufferInfo.bitsPerPixel),
      vImage_Flags(kvImageNoFlags)
    )
    if initError != kvImageNoError {
      return nil
    }
    defer {
      free(destinationBuffer.data)
    }
    let error = vImageConvert_PlanarFtoPlanar8(
      &sourceBuffer,
      &destinationBuffer,
      1,
      0,
      vImage_Flags(kvImageNoFlags)
    )
    if error != kvImageNoError {
      return nil
    }
    guard var destinationPixelBuffer = createPixelBuffer(with: pixelBufferPool) else {
      return nil
    }
    guard case .some = copy(
      buffer: &destinationBuffer,
      to: &destinationPixelBuffer,
      bufferInfo: destinationBufferInfo
      ) else {
        return nil
    }
    return HSPixelBuffer(pixelBuffer: destinationPixelBuffer)
  })
}
