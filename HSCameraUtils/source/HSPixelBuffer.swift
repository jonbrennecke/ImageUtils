import AVFoundation

struct HSPixelBuffer<T: Numeric> {
  internal typealias PixelValueType = T

  private let buffer: CVPixelBuffer

  public let size: Size<Int>

  init(pixelBuffer buffer: CVPixelBuffer) {
    self.buffer = buffer
    size = pixelSizeOf(buffer: buffer)
  }

  public var bytesPerRow: Int {
    return withLockedBaseAddress(buffer) { buffer in
      CVPixelBufferGetBytesPerRow(buffer)
    }
  }

  public func forEachPixel(in rect: Rectangle<Int>, _ callback: (T, Int, Point2D<Int>) -> Void) {
    return withLockedBaseAddress(buffer) { buffer in
      let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer) / MemoryLayout<T>.size
      let ptr = unsafeBitCast(CVPixelBufferGetBaseAddress(buffer), to: UnsafeMutablePointer<T>.self)
      rect.forEach { index2D in
        let pixel = ptr[index2D.flatIndex(forWidth: bytesPerRow)]
        let i = (index2D.y - rect.y) * rect.width + (index2D.x - rect.x)
        callback(pixel, i, index2D)
      }
    }
  }

  public func forEachPixel(in size: Size<Int>, _ callback: (T, Int, Point2D<Int>) -> Void) {
    return forEachPixel(in: Rectangle(origin: .zero(), size: size), callback)
  }

  public func forEachPixel(_ callback: (T, Int, Point2D<Int>) -> Void) {
    return forEachPixel(in: size, callback)
  }

  public func mapPixels<R: Numeric>(_ transform: (T, Point2D<Int>) -> R) -> [R] {
    let length = size.width * size.height
    var ret = [R](repeating: 0, count: length)
    forEachPixel { pixel, i, index2D in
      ret[i] = transform(pixel, index2D)
    }
    return ret
  }

  public func getBytes() -> [UInt8] {
    let length = size.width * size.height * MemoryLayout<T>.size
    var ret = [UInt8](repeating: 0, count: length)
    forEachPixel { pixel, i, _ in
      let index = i * MemoryLayout<T>.size
      var pixel = pixel
      memcpy(&ret[index], &pixel, MemoryLayout<T>.size)
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
}
