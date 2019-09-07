import AVFoundation

public class HSVideoWriterAudioInput: HSVideoWriterInput {
  public typealias InputType = CMSampleBuffer

  private let audioInput: AVAssetWriterInput

  public var isEnabled: Bool = true {
    didSet {
      audioInput.marksOutputTrackAsEnabled = isEnabled
    }
  }

  public var input: AVAssetWriterInput {
    return audioInput
  }

  public init(isRealTime: Bool = true) {
    let outputSettings: [String: Any] = [
      AVNumberOfChannelsKey: 1,
      AVSampleRateKey: 44100,
      AVEncoderAudioQualityForVBRKey: 91,
      AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Variable,
      AVFormatIDKey: kAudioFormatMPEG4AAC,
      AVEncoderBitRatePerChannelKey: 96000
    ]
    audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings)
    audioInput.expectsMediaDataInRealTime = isRealTime
  }

  public func append(_ sampleBuffer: CMSampleBuffer) {
    if input.isReadyForMoreMediaData {
      input.append(sampleBuffer)
    }
  }

  public func finish() {
    input.markAsFinished()
  }
}
