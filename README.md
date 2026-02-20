# CVSwift

Swift SDK for running computer vision models in iOS/macOS apps with a few lines of code.

Supports Roboflow-hosted, on-device CoreML models and hope more in the future.

## Usage

### Basic Usage(for Roboflow Object Detection models)

```Swift
import CVSwift
import SwiftUI

struct ContentView: View {
   @State private var observations: [ObjectDetectionObservation] = []
   
   var body: some View {
      VideoObjectDetectionView(videoURL: your-video-url, observations: observations)
         .task {
            let vod = VideoObjectDetector()
            observations = try! await vod.processRoboflowModel(
               modelId: "basketball-player-detection-2", // Roboflow modelId
               modelVersion: 16, // model version
               videoURL: your-video-url,
               apiKey: your-roboflow-apikey
            )
         }
   }
}
```

## Installation

#### Requirements

- iOS 16.0+
- macOS 13.0+
- Swift 5.9+

#### Via Swift Package Manager

- Go to File > Add Package Dependencies...
- Paste https://github.com/alpaycli/CVSwift.git
- Select the version and add the package to your project.

## Credits

Uses [roboflow-swift](https://github.com/roboflow/roboflow-swift.git)

## License

CVSwift is available under the MIT license. See the LICENSE file for more info.

## Contributions

Contributions are welcome! If you have any suggestions or improvements, please create an issue or submit a pull request.
