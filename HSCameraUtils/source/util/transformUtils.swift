import Accelerate
import AVFoundation

public func map<T: Numeric, R: Numeric>(
  _ iterator: HSPixelBufferIterator<T>,
  pixelFormatType: OSType,
  pixelBufferPool: CVPixelBufferPool,
  transform: (T) -> R
) -> HSPixelBufferIterator<R>? {
  var pixels = iterator.mapPixels { x, _ in transform(x) }
  let pixelBuffer = iterator.pixelBuffer
  let destBufferInfo = HSBufferInfo(pixelFormatType: pixelFormatType)
  let destHeight = pixelBuffer.size.height
  let destWidth = pixelBuffer.size.width
  let destBytesPerRow = destWidth * destBufferInfo.bytesPerPixel
  var destBuffer = vImage_Buffer(
    data: &pixels,
    height: vImagePixelCount(destHeight),
    width: vImagePixelCount(destWidth),
    rowBytes: destBytesPerRow
  )
  guard var destPixelBuffer = createPixelBuffer(with: pixelBufferPool) else {
    return nil
  }
  guard case .some = copy(buffer: &destBuffer, to: &destPixelBuffer, bufferInfo: destBufferInfo) else {
    return nil
  }
  let buffer = HSPixelBuffer(pixelBuffer: destPixelBuffer)
  return HSPixelBufferIterator(pixelBuffer: buffer)
}
