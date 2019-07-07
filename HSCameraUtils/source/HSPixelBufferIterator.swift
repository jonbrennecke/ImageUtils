import Accelerate
import AVFoundation

public struct HSPixelBufferIterator<T: Numeric> {
  public let pixelBuffer: HSPixelBuffer

  public var size: Size<Int> {
    return pixelBuffer.size
  }

  public func forEachPixel(in rect: Rectangle<Int>, _ callback: (T, Int, Point2D<Int>) -> Void) {
    pixelBuffer.withDataPointer { rawPtr in
      let ptr = UnsafeMutablePointer<T>(OpaquePointer(rawPtr.assumingMemoryBound(to: T.self)))
      let bytesPerRow = pixelBuffer.bytesPerRow
      let pixelsPerRow = bytesPerRow / pixelBuffer.bufferInfo.bytesPerPixel
      rect.forEach { index2D in
        let index = (index2D.y - rect.y) * rect.width + (index2D.x - rect.x)
        let ptrIndex = index2D.y * pixelsPerRow + index2D.x
        let pixel = ptr[ptrIndex]
        callback(pixel, index, index2D)
      }
    }
  }

  public func forEachPixel(in size: Size<Int>, _ callback: (T, Int, Point2D<Int>) -> Void) {
    return forEachPixel(in: Rectangle(origin: .zero(), size: size), callback)
  }

  public func forEachPixel(_ callback: (T, Int, Point2D<Int>) -> Void) {
    return forEachPixel(in: pixelBuffer.size, callback)
  }

  public func mapPixels<R: Numeric>(_ transform: (T, Point2D<Int>) -> R) -> [R] {
    let length = pixelBuffer.size.width * pixelBuffer.size.height
    var ret = [R](repeating: 0, count: length)
    forEachPixel { pixel, i, index2D in
      ret[i] = transform(pixel, index2D)
    }
    return ret
  }

  public func getPixels() -> [T] {
    return mapPixels { px, _ in px }
  }

  public func getPixels(in rect: Rectangle<Int>) -> [T] {
    let length = rect.width * rect.height
    var ret = [T](repeating: 0, count: length)
    forEachPixel(in: rect) { pixel, i, _ in
      ret[i] = pixel
    }
    return ret
  }

  public func getBytes() -> [UInt8] {
    let bytesPerPixel = pixelBuffer.bufferInfo.bytesPerPixel
    let length = pixelBuffer.size.width * pixelBuffer.size.height * bytesPerPixel
    var ret = [UInt8](repeating: 0, count: length)
    forEachPixel { pixel, i, _ in
      let index = i * bytesPerPixel
      var pixel = pixel
      memcpy(&ret[index], &pixel, bytesPerPixel)
    }
    return ret
  }

//  public func byMapping<R: Numeric>(
//    to bufferInfo: HSBufferInfo, _ transform: (T, Point2D<Int>) -> R
//  ) -> HSPixelBufferIterator<R>? {
//    var pixels = mapPixels(transform)
//    let srcHeight = vImagePixelCount(pixelBuffer.size.height)
//    let srcWidth = vImagePixelCount(pixelBuffer.size.width)
//    let srcBytesPerRow = pixelBuffer.size.width * bufferInfo.bytesPerPixel
//    var srcBuffer = vImage_Buffer(data: &pixels, height: srcHeight, width: srcWidth, rowBytes: srcBytesPerRow)
//    let destTotalBytes = pixels.count * bufferInfo.bytesPerPixel
//    let destBytesPerRow = pixelBuffer.size.width * bufferInfo.bytesPerPixel
//    guard let destData = malloc(destTotalBytes) else {
//      return nil
//    }
//    let destHeight = vImagePixelCount(pixelBuffer.size.height)
//    let destWidth = vImagePixelCount(pixelBuffer.size.width)
//    var destBuffer = vImage_Buffer(data: destData, height: destHeight, width: destWidth, rowBytes: destBytesPerRow)
//    let error = vImageScale_ARGB8888(&srcBuffer, &destBuffer, nil, vImage_Flags(0))
//    if error != kvImageNoError {
//      free(destData)
//      return nil
//    }
//    let attrs = [
//      kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
//      kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
//      ] as CFDictionary
//    let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
//      if let ptr = ptr {
//        free(UnsafeMutableRawPointer(mutating: ptr))
//      }
//    }
//    var destPixelBuffer: CVPixelBuffer!
//    let status = CVPixelBufferCreateWithBytes(
//      kCFAllocatorDefault,
//      pixelBuffer.size.width,
//      pixelBuffer.size.height,
//      bufferInfo.pixelFormatType,
//      destData,
//      destBytesPerRow,
//      releaseCallback,
//      destData,
//      attrs,
//      &destPixelBuffer
//    )
//    guard status == kCVReturnSuccess else {
//      return nil
//    }
//    let buffer = HSPixelBuffer(pixelBuffer: destPixelBuffer)
//    return HSPixelBufferIterator<R>(pixelBuffer: buffer)
//  }
}

extension HSPixelBufferIterator where T: FloatingPoint {
  public func bounds() -> ClosedRange<T> {
    var min: T = T.greatestFiniteMagnitude
    var max: T = T.leastNonzeroMagnitude
    forEachPixel { x, _, _ in
      if x < min {
        min = x
      } else if x > max {
        max = x
      }
    }
    return min ... max
  }
}

extension HSPixelBufferIterator where T: FixedWidthInteger {
  public func bounds() -> ClosedRange<T> {
    var min: T = T.max
    var max: T = T.min
    forEachPixel { x, _, _ in
      if x < min {
        min = x
      } else if x > max {
        max = x
      }
    }
    return min ... max
  }
}
