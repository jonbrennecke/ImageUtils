import AVFoundation

public protocol HSVideoWriterInput {
  associatedtype InputType
  var input: AVAssetWriterInput { get }
  var isEnabled: Bool { get set }
  func append(_: InputType)
  func finish()
}
