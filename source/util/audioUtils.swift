import AVFoundation

public enum CreateAudioFileFailure: Error {
  case failedToCreateExportSession
  case assetMissingAudioTrack
  case failedToExportAudioFile
}

public func createTemporaryAudioFile(
  fromAsset asset: AVAsset,
  completionHandler: @escaping (Result<URL, CreateAudioFileFailure>) -> Void
) {
  let audioAssetTracks = asset.tracks(withMediaType: .audio)
  guard let audioAssetTrack = audioAssetTracks.last else {
    return completionHandler(.failure(.assetMissingAudioTrack))
  }
  guard
    let outputURL = try? makeEmptyTemporaryFile(withPathExtension: "aiff"),
    let assetExportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
  else {
    return completionHandler(.failure(.failedToCreateExportSession))
  }
  assetExportSession.outputURL = outputURL
  assetExportSession.outputFileType = .aiff
  assetExportSession.timeRange = audioAssetTrack.timeRange
  assetExportSession.exportAsynchronously {
    if assetExportSession.status == .failed {
      return completionHandler(.failure(.failedToExportAudioFile))
    }
    completionHandler(.success(outputURL))
  }
}

fileprivate func makeEmptyTemporaryFile(withPathExtension pathExtension: String) throws -> URL {
  let outputTemporaryDirectoryURL = try FileManager.default
    .url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: FileManager.default.temporaryDirectory,
      create: true
    )
  let outputURL = outputTemporaryDirectoryURL
    .appendingPathComponent(makeRandomFileName())
    .appendingPathExtension(pathExtension)
  try? FileManager.default.removeItem(at: outputURL)
  return outputURL
}

fileprivate func makeRandomFileName() -> String {
  let random_int = arc4random_uniform(.max)
  return NSString(format: "%x", random_int) as String
}
