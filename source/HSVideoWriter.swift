import AVFoundation

public class HSVideoWriter {
  internal static let queue = DispatchQueue(label: "com.jonbrennecke.HSVideoWriter.inputQueue")
  
  private enum State {
    case notReady
    case readyToRecord(assetWriter: AVAssetWriter)
    case recording(assetWriter: AVAssetWriter, startTime: CMTime)
  }

  // TODO: rename
  public enum HSVideoWriterResult {
    case success
    case failure
  }

  private var state: State

  public init() {
    state = .notReady
  }

  public func prepareToRecord(to url: URL) -> HSVideoWriterResult {
    guard let assetWriter = try? AVAssetWriter(outputURL: url, fileType: .mov) else {
      return .failure
    }
    state = .readyToRecord(assetWriter: assetWriter)
    return .success
  }

  public func add<T: HSVideoWriterInput>(input: T) -> HSVideoWriterResult {
    guard case let .readyToRecord(assetWriter) = state else {
      return .failure
    }
    if assetWriter.canAdd(input.input) {
      assetWriter.add(input.input)
      return .success
    }
    return .failure
  }

  public func startRecording(at startTime: CMTime) -> HSVideoWriterResult {
    guard case let .readyToRecord(assetWriter) = state else {
      return .failure
    }
    state = .recording(assetWriter: assetWriter, startTime: startTime)
    if !assetWriter.startWriting() {
      return .failure
    }
    assetWriter.startSession(atSourceTime: .zero)
    return .success
  }

  public func stopRecording(at endTime: CMTime, _ completionHandler: @escaping (URL) -> Void) {
    guard case let .recording(assetWriter, startTime) = state else {
      return
    }
    assetWriter.endSession(atSourceTime: endTime - startTime)
    assetWriter.finishWriting {
      completionHandler(assetWriter.outputURL)
    }
  }
}

public protocol HSVideoWriterInput {
  associatedtype InputType
  var input: AVAssetWriterInput { get }
  var isEnabled: Bool { get set }
  func append(_: InputType)
  func finish()
}

public class HSVideoWriterMetadataInput : HSVideoWriterInput {
  public typealias InputType = AVTimedMetadataGroup
  
  private let metadataInput: AVAssetWriterInput
  private let metadataAdaptor: AVAssetWriterInputMetadataAdaptor
  
  public var isEnabled: Bool = true {
    didSet {
      metadataInput.marksOutputTrackAsEnabled = isEnabled
    }
  }
  
  public var input: AVAssetWriterInput {
    get {
      return metadataInput
    }
  }

  init(isRealTime: Bool = true) {
    metadataInput = AVAssetWriterInput(mediaType: .metadataObject, outputSettings: nil)
    metadataInput.expectsMediaDataInRealTime = isRealTime
    metadataAdaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: metadataInput)
  }
  
  public func append(_ timedMetadataGroup: AVTimedMetadataGroup) {
    if input.isReadyForMoreMediaData {
      metadataAdaptor.append(timedMetadataGroup)
    }
  }
  
  public func finish() {
    metadataInput.markAsFinished()
  }
}

public class HSVideoWriterFrameBufferInput : HSVideoWriterInput {
  public typealias InputType = HSVideoFrameBuffer
  
  private let videoInput: AVAssetWriterInput
  private let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
  
  public var isEnabled: Bool = true {
    didSet {
      videoInput.marksOutputTrackAsEnabled = isEnabled
    }
  }
  
  public var input: AVAssetWriterInput {
    get {
      return videoInput
    }
  }
  
  public init(videoSize: Size<Int>, pixelFormatType: OSType, isRealTime: Bool = true) {
    let videoSettings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: videoSize.width as NSNumber,
      AVVideoHeightKey: videoSize.height as NSNumber,
    ]
    videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    videoInput.expectsMediaDataInRealTime = isRealTime
    pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: videoInput,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey: pixelFormatType,
        kCVPixelBufferWidthKey: videoSize.width,
        kCVPixelBufferHeightKey: videoSize.height,
      ] as [String: Any]
    )
  }
  
  public func append(_ videoFrameBuffer: HSVideoFrameBuffer) {
    if input.isReadyForMoreMediaData {
      let buffer = videoFrameBuffer.pixelBuffer.buffer
      pixelBufferAdaptor.append(buffer, withPresentationTime: videoFrameBuffer.presentationTime)
    }
  }
  
  public func finish() {
    videoInput.markAsFinished()
  }
}
