import CoreVideo
import UIKit
import Accelerate

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

public func createPixelBuffer(with pool: CVPixelBufferPool) -> CVPixelBuffer? {
  var destPixelBuffer: CVPixelBuffer!
  let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &destPixelBuffer)
  guard status == kCVReturnSuccess else {
    return nil
  }
  return destPixelBuffer
}

public func copy(buffer: inout vImage_Buffer, to pixelBuffer: inout CVPixelBuffer, bufferInfo: HSBufferInfo) -> CVPixelBuffer? {
  var cgImageFormat = vImage_CGImageFormat(
    bitsPerComponent: UInt32(bufferInfo.bitsPerComponent),
    bitsPerPixel: UInt32(bufferInfo.bitsPerPixel),
    colorSpace: Unmanaged.passRetained(bufferInfo.colorSpace),
    bitmapInfo: bufferInfo.bitmapInfo,
    version: 0,
    decode: nil,
    renderingIntent: .defaultIntent
  )
  
  guard let cvImageFormat = vImageCVImageFormat_CreateWithCVPixelBuffer(pixelBuffer)?.takeRetainedValue() else {
    return nil
  }
  vImageCVImageFormat_SetColorSpace(cvImageFormat, bufferInfo.colorSpace)
  
  let copyError = vImageBuffer_CopyToCVPixelBuffer(
    &buffer,
    &cgImageFormat,
    pixelBuffer,
    cvImageFormat,
    nil,
    vImage_Flags(kvImageNoFlags)
  )
  
  if copyError != kvImageNoError {
    return nil
  }
  
  return pixelBuffer
}
