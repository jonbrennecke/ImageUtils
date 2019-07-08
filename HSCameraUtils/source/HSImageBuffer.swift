import AVFoundation
import Accelerate

public struct HSImageBuffer {
  public let pixelBuffer: HSPixelBuffer

  public var size: Size<Int> {
    return pixelBuffer.size
  }

  public init(pixelBuffer: HSPixelBuffer) {
    self.pixelBuffer = pixelBuffer
  }
  
  public init(cvPixelBuffer buffer: CVPixelBuffer) {
    self.pixelBuffer = HSPixelBuffer(pixelBuffer: buffer)
  }
  
  public func makeVImageBuffer() -> vImage_Buffer {
    return pixelBuffer.withMutableDataPointer { ptr -> vImage_Buffer in
      return vImage_Buffer(
        data: ptr,
        height: vImagePixelCount(size.height),
        width: vImagePixelCount(size.width),
        rowBytes: pixelBuffer.bytesPerRow
      )
    }
  }
  
  public func makeImage() -> CGImage? {
    var buffer = makeVImageBuffer()
    let bufferInfo = pixelBuffer.bufferInfo
    var cgImageFormat = vImage_CGImageFormat(
      bitsPerComponent: UInt32(bufferInfo.bitsPerComponent),
      bitsPerPixel: UInt32(bufferInfo.bitsPerPixel),
      colorSpace: Unmanaged.passRetained(bufferInfo.colorSpace),
      bitmapInfo: bufferInfo.bitmapInfo,
      version: 0,
      decode: nil,
      renderingIntent: .defaultIntent
    )
    var error: vImage_Error = kvImageNoError
    let image = vImageCreateCGImageFromBuffer(
      &buffer,
      &cgImageFormat,
      nil,
      nil,
      vImage_Flags(kvImageNoFlags),
      &error
    )
    guard error == kvImageNoError else {
      return nil
    }
    return image?.takeRetainedValue()
  }
  
  public func resize(
    to outputSize: Size<Int>,
    pixelBufferPool: CVPixelBufferPool,
    isGrayscale: Bool = false
  ) -> HSImageBuffer? {
    let bufferInfo = pixelBuffer.bufferInfo
    var srcBuffer = makeVImageBuffer()
    
    // create an empty destination vImage_Buffer
    let destHeight = vImagePixelCount(outputSize.height)
    let destWidth = vImagePixelCount(outputSize.width)
    let destTotalBytes = outputSize.height * outputSize.width * bufferInfo.bytesPerPixel
    let destBytesPerRow = outputSize.width * bufferInfo.bytesPerPixel
    guard let destData = malloc(destTotalBytes) else {
      return nil
    }
    var destBuffer = vImage_Buffer(
      data: destData,
      height: destHeight,
      width: destWidth,
      rowBytes: destBytesPerRow
    )
    
    // scale
    let resizeFlags = vImage_Flags(kvImageHighQualityResampling)
    if isGrayscale {
      let error = vImageScale_Planar8(&srcBuffer, &destBuffer, nil, resizeFlags)
      if error != kvImageNoError {
        free(destData)
        return nil
      }
    } else {
      let error = vImageScale_ARGB8888(&srcBuffer, &destBuffer, nil, resizeFlags)
      if error != kvImageNoError {
        free(destData)
        return nil
      }
    }
    
    guard let destPixelBuffer = createPixelBuffer(with: pixelBufferPool) else {
      free(destData)
      return nil
    }
    
    // save vImageBuffer to CVPixelBuffer
    
    var cgImageFormat = vImage_CGImageFormat(
      bitsPerComponent: UInt32(bufferInfo.bitsPerComponent),
      bitsPerPixel: UInt32(bufferInfo.bitsPerPixel),
      colorSpace: Unmanaged.passRetained(bufferInfo.colorSpace),
      bitmapInfo: bufferInfo.bitmapInfo,
      version: 0,
      decode: nil,
      renderingIntent: .defaultIntent
    )
    
    guard let cvImageFormat = vImageCVImageFormat_CreateWithCVPixelBuffer(destPixelBuffer)?.takeRetainedValue() else {
      free(destData)
      return nil
    }
    vImageCVImageFormat_SetColorSpace(cvImageFormat, bufferInfo.colorSpace)
    
    let copyError = vImageBuffer_CopyToCVPixelBuffer(
      &destBuffer,
      &cgImageFormat,
      destPixelBuffer,
      cvImageFormat,
      nil,
      vImage_Flags(kvImageNoFlags)
    )
    
    if copyError != kvImageNoError {
      free(destData)
      return nil
    }
    free(destData)
    return HSImageBuffer(cvPixelBuffer: destPixelBuffer)
  }
}
