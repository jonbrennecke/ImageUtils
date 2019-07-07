import CoreVideo
import UIKit

internal func withLockedBaseAddress<T>(
  _ buffer: CVPixelBuffer,
  flags: CVPixelBufferLockFlags = .readOnly,
  _ callback: (CVPixelBuffer) -> T
) -> T {
  CVPixelBufferLockBaseAddress(buffer, flags)
  let ret = callback(buffer)
  CVPixelBufferUnlockBaseAddress(buffer, flags)
  return ret
}

internal func pixelSizeOf<T: Numeric>(buffer: CVPixelBuffer) -> Size<T> {
  return withLockedBaseAddress(buffer) { buffer in
    let width = CVPixelBufferGetWidth(buffer)
    let height = CVPixelBufferGetHeight(buffer)
    return Size<T>(width: T(exactly: width)!, height: T(exactly: height)!)
  }
}

public func createBuffer(
  data: UnsafeMutableRawPointer,
  size: Size<Int>,
  bytesPerRow: Int,
  pixelFormatType: OSType,
  releaseCallback: CVPixelBufferReleaseBytesCallback?
) -> CVPixelBuffer? {
  let attrs = [
    kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
  ] as CFDictionary
  var buffer: CVPixelBuffer!
  let status = CVPixelBufferCreateWithBytes(
    kCFAllocatorDefault,
    size.width,
    size.height,
    pixelFormatType,
    data,
    bytesPerRow,
    releaseCallback,
    nil,
    attrs,
    &buffer
  )
  guard status == kCVReturnSuccess else {
    return nil
  }
  return buffer
}
