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
