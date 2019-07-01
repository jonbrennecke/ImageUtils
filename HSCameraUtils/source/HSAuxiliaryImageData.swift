import AVFoundation
import CoreImage

@available(iOS 12.0, *)
class HSAuxiliaryImageData {
    public let image: CGImage
    
    public lazy var ciImage: CIImage = {
        CIImage(cgImage: image)
    }()
    
    private let segmentationMatte: AVPortraitEffectsMatte
    public lazy var segmentationMatteBuffer: HSPixelBuffer<UInt8> = {
        HSPixelBuffer<UInt8>(pixelBuffer: segmentationMatte.mattingImage)
    }()
    
    private let depthData: AVDepthData
    public lazy var depthBuffer: HSPixelBuffer<Float32> = {
        HSPixelBuffer<Float32>(pixelBuffer: depthData.depthDataMap)
    }()
    
    init?(data: Data) {
        guard
            let imageSource = createImageSource(with: data),
            let depthData = createDepthData(with: imageSource),
            let matte = createSegmentationMatte(with: imageSource),
            let image = createImage(with: imageSource)
            else {
                return nil
        }
        segmentationMatte = matte
        self.depthData = depthData
        self.image = image
    }
    
    public lazy var face: CIFaceFeature? = {
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options) else {
            return nil
        }
        let faces = faceDetector.features(in: ciImage)
        return faces.first as? CIFaceFeature
    }()
    
    public lazy var faceRectangle: Rectangle<Int>? = {
        guard let face = face else {
            return nil
        }
        let x = Int(exactly: face.bounds.minX.rounded())!
        let y = Int(exactly: face.bounds.minY.rounded())!
        let width = Int(exactly: face.bounds.width.rounded())!
        let height = Int(exactly: face.bounds.height.rounded())!
        let origin = Point2D(x: x, y: y)
        let size = Size(width: width, height: height)
        return Rectangle(origin: origin, size: size)
    }()
    
    public var imageSize: Size<Int> {
        return Size(width: image.width, height: image.height)
    }
    
    public var depthSize: Size<Int> {
        return depthBuffer.size
    }
    
    // TODO: methods below should not be part of this class
    
    public func toDepthCoords(from p: Point2D<Int>) -> Point2D<Int> {
        return translate(p, from: imageSize, to: depthSize)
    }
    
    public func toDepthCoords(from s: Size<Int>) -> Size<Int> {
        return translate(s, from: imageSize, to: depthSize)
    }
    
    public func toDepthCoords(from rect: Rectangle<Int>) -> Rectangle<Int> {
        let origin = toDepthCoords(from: rect.origin)
        let size = toDepthCoords(from: rect.size)
        return Rectangle(origin: origin, size: size)
    }
}
