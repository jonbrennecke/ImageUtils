import AVFoundation
import Accelerate

public struct HSImageBuffer {
  private let pixelBuffer: HSPixelBuffer

  public var size: Size<Int> {
    return pixelBuffer.size
  }

  public init(pixelBuffer: HSPixelBuffer) {
    self.pixelBuffer = pixelBuffer
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
}
