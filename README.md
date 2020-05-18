ImageUtils
----

Low-level image and video processing utilities for high-performance apps.

## Motivation

This library came about during the creation of my app [BOCA](https://apps.apple.com/us/app/boca-portrait-mode-videos/id1478361742). BOCA captures "portrait mode" in realtime and needed efficient processing of depth data. The methods to convert between AVDepthData and CIImage are quite a bit faster than the built-in methods in the standard iOS SDK.

See [DepthBlurFilter](https://github.com/jonbrennecke/Camera/blob/master/Source/filters/DepthBlurFilter.swift) for the implemtation of the depth-of-field "Portrait Mode" effect.

## PixelBuffer

The fundamental component of this library is `PixelBuffer`. A PixelBuffer is a wrapper around a `CVPixelBuffer` that adds a few useful methods.

#### Create a PixelBuffer with a CVPixelBuffer
```swift
public init(pixelBuffer buffer: CVPixelBuffer)
```

#### Create a PixelBuffer with AVDepthData
```swift
public init(depthData: AVDepthData)
```

#### Create a PixelBuffer with a CMSampleBuffer
```swift
public init?(sampleBuffer: CMSampleBuffer)
```

## ImageBuffer

The `ImageBuffer` struct wraps a `PixelBuffer` with a few extra image processing functions.

#### Create a vImage_Buffer from an ImageBuffer.
```swift
public func makeVImageBuffer() -> vImage_Buffer
```

#### Create a CGImage from an ImageBuffer
```swift
public func makeCGImage() -> CGImage?
```

#### Create a CIImage from an ImageBuffer
```swift
public func makeCIImage() -> CIImage?
```

#### Create a resized image buffer
```swift
public func resize(
  to outputSize: Size<Int>,
  pixelBufferPool: CVPixelBufferPool,
  isGrayscale: Bool = false
) -> ImageBuffer?
  ```
