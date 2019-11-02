import XCTest
import Photos
import AVFoundation
import HSCameraUtils

class AudioTests: XCTestCase {
  func testAudioCompression() {
    let expectation = self.expectation(description: "testAudioCompression")
    var error: Error?
    var outputURL: URL?
    loadTestVideoAsset() { result in
      switch result {
      case let .success(asset):
        createDownSampledAudio(asset: asset) { downsampleResult in
          switch downsampleResult {
          case let .success(url):
            outputURL = url
            expectation.fulfill()
          case let .failure(err):
            error = err
            expectation.fulfill()
          }
        }
      case let .failure(err):
        error = err
        expectation.fulfill()
      }
    }
    waitForExpectations(timeout: 10000)
    XCTAssert(error == nil)
    XCTAssert(outputURL != nil)
  }
}

fileprivate enum LoadTestVideoError: Error {
  case failedToFindVideoInBundle
}

fileprivate func loadTestVideoAsset(_ completionHandler: @escaping (Result<AVAsset, LoadTestVideoError>) -> Void) {
  let bundle = Bundle.init(for: AudioTests.classForCoder())
  guard let url = bundle.url(forResource: "test_video", withExtension: "mov") else {
    return completionHandler(.failure(.failedToFindVideoInBundle))
  }
  let asset = AVAsset(url: url)
  asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
    completionHandler(.success(asset))
  }
}
