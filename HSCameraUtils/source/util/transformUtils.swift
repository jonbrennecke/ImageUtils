import Accelerate
import AVFoundation

public func resize(
  _ pixelBuffer: HSPixelBuffer,
  to outputSize: Size<Int>,
  pixelBufferPool: CVPixelBufferPool,
  isGrayscale: Bool = false
) -> HSPixelBuffer? {
  let bufferInfo = pixelBuffer.bufferInfo

  // create a source vImage_Buffer from pixel data
  var srcBuffer = pixelBuffer.withMutableDataPointer { ptr -> vImage_Buffer in
    let srcHeight = vImagePixelCount(pixelBuffer.size.height)
    let srcWidth = vImagePixelCount(pixelBuffer.size.width)
    // let srcBytesPerRow = pixelBuffer.size.width * bufferInfo.bytesPerPixel
    let srcBytesPerRow = pixelBuffer.bytesPerRow
    return vImage_Buffer(
      data: ptr,
      height: srcHeight,
      width: srcWidth,
      rowBytes: srcBytesPerRow
    )
  }

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
  return HSPixelBuffer(pixelBuffer: destPixelBuffer)
}

public func map<T: Numeric, R: Numeric>(
  _ iterator: HSPixelBufferIterator<T>,
  to pixelFormatType: OSType,
  transform: (T) -> R
) -> HSPixelBufferIterator<R>? {
  var pixels = iterator.mapPixels { x, _ in transform(x) }
  let pixelBuffer = iterator.pixelBuffer
  let destBufferInfo = HSBufferInfo(pixelFormatType: pixelFormatType)

  let destHeight = pixelBuffer.size.height
  let destWidth = pixelBuffer.size.width
  let destTotalBytes = destHeight * destWidth * destBufferInfo.bytesPerPixel
  let destBytesPerRow = destWidth * destBufferInfo.bytesPerPixel
  guard let destData = malloc(destTotalBytes) else {
    return nil
  }
  memcpy(destData, &pixels, destTotalBytes)

  // create output CVPixelBuffer
  let attrs = [
    kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
  ] as CFDictionary
  let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
    if let ptr = ptr {
      free(UnsafeMutableRawPointer(mutating: ptr))
    }
  }
  var destPixelBuffer: CVPixelBuffer!
  let status = CVPixelBufferCreateWithBytes(
    kCFAllocatorDefault,
    Int(destWidth),
    Int(destHeight),
    destBufferInfo.pixelFormatType,
    destData,
    destBytesPerRow,
    releaseCallback,
    nil,
    attrs,
    &destPixelBuffer
  )
  guard status == kCVReturnSuccess else {
    free(destData)
    return nil
  }
  let buffer = HSPixelBuffer(pixelBuffer: destPixelBuffer)
  return HSPixelBufferIterator(pixelBuffer: buffer)
}
