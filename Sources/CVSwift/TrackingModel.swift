//
//  TrackingModel.swift
//  CVSwift
//
//  Created by Alpay Calalli on 11.02.26.
//

import Combine
import Vision
import Foundation

enum TrackingError: Error {
   case loadingFailed(message: String)
   case noFrameAvailable
   case detectionFailed(message: String)
   
   var message: String {
      switch self {
            
         case .loadingFailed(message: let message):
            return message
         case .noFrameAvailable:
            return "No Frame Available."
         case .detectionFailed(message: let message):
            return message
      }
   }
}

// Rest, Hopefully will be implemented soon.

/// For uploaded video.
struct TrackableObject: Identifiable {
    var id: Int
    var rect: CGRect
    var firstDetectFrame: Int
    var lastDetectFrame: Int
    
    var totalDetectionFrame: Int {
        lastDetectFrame - firstDetectFrame + 1
    }

}

class VideoTrackingModel: ObservableObject {
    
    enum videoProcessingState {
        case none
        case loading
        case loaded
        case processing
        case processed
    }
    
    let tracker = CentroidTracker(maxDisappearedFrameCount: 20, maxNormalizedDistance: 0.2)
    let videoManager: VideoManager = VideoManager()
    
    let defaultFrameDuration = 0.04
    
    
    @Published var error: TrackingError? = nil {
        didSet {
            if self.processingState == .loading {
                self.processingState = .none
            }
        }
    }
    @Published var processingState: VideoTrackingModel.videoProcessingState = .none
    
    @Published var frames: [CGImage] = []
    @Published var trackedObjectsPerFrame: [[TrackableObject]] = []

    @Published var trackedObjects: [TrackableObject] = []
    @Published var deregisteredObjects: [TrackableObject] = []
    
    var fractionProcessed: Double {
        guard let totalDuration = videoManager.duration, let frameDuration = videoManager.minFrameDuration else {return 0}
        return min(frameDuration*Double(frames.count)/totalDuration, 1.0)
    }
    
    var averageTrackedTime: Float {
        if trackedObjects.isEmpty && deregisteredObjects.isEmpty {
            return 0.0
        }
        let frameDuration = Float(videoManager.minFrameDuration ?? defaultFrameDuration)
        
        let currentlyTrackingTotal = trackedObjects.map({$0.totalDetectionFrame}).reduce(0, +)
        let deregisteredTotal = deregisteredObjects.map({$0.totalDetectionFrame}).reduce(0, +)
        let average = Float(currentlyTrackingTotal + deregisteredTotal) * frameDuration / Float(trackedObjects.count + deregisteredObjects.count)
        return average
    }
    
    
    private let thresholdConfidence: Float = 0.0

    
    @MainActor
    private func processObservations(_ observations: [ObjectDetectionObservation], for frame: Int) {
        let boundingBoxes = observations.filter({$0.confidence > thresholdConfidence}).map({$0.boundingBox})
        tracker.update(rects: boundingBoxes)
        
        let currentTrackedObject = self.trackedObjects
        
        let updatedTrackedRects = tracker.objects
        let rectsInFrame = tracker.objectsInFrame
        let deregisteredObjectsId = tracker.deregisteredObjects
        

        // update deregistered object
        let newlyDeregisteredObjects = currentTrackedObject.filter({deregisteredObjectsId.contains($0.id)})
        self.deregisteredObjects.append(contentsOf: newlyDeregisteredObjects)
        trackedObjects.removeAll(where: {deregisteredObjectsId.contains($0.id)})
        
        var trackedObjectsInFrame: [TrackableObject] = []
        
        for rect in updatedTrackedRects {
            let firstTrackedIndex = trackedObjects.firstIndex(where: {$0.id == rect.key})
            
            // temporarily disappeared objects
            if !rectsInFrame.contains(where: {$0.key == rect.key}) {
                if let firstTrackedIndex = firstTrackedIndex {
                    self.trackedObjects[firstTrackedIndex].lastDetectFrame = frame
                }
                continue
            }

            // objects in frame
            if let firstTrackedIndex = firstTrackedIndex {
                self.trackedObjects[firstTrackedIndex].rect = rect.value
                self.trackedObjects[firstTrackedIndex].lastDetectFrame = frame
                trackedObjectsInFrame.append(self.trackedObjects[firstTrackedIndex])
            } else {
                let newObject = TrackableObject(id: rect.key, rect: rect.value, firstDetectFrame: frame, lastDetectFrame: frame)
                self.trackedObjects.append(newObject)
                trackedObjectsInFrame.append(newObject)
            }
        }
        
        self.trackedObjectsPerFrame.append(trackedObjectsInFrame)
//        print(self.trackedObjectsPerFrame)

    }
    
    
//    func convertRect(normalizedRect: CGRect, imageSize: CGSize) -> CGRect {
//        if normalizedRect == .zero {
//            return .zero
//        }
//       // Assuming 'observation' is VNRectangleObservation and 'image' is UIImage
//       let imageWidth = imageSize.width
//       let imageHeight = imageSize.height
//
//       let rect = CGRect(
//           x: normalizedRect.origin.x * imageWidth,
//           y: (1 - normalizedRect.origin.y - normalizedRect.size.height) * imageHeight,
//           width: normalizedRect.size.width * imageWidth,
//           height: normalizedRect.size.height * imageHeight
//       )
//
//       return rect
//    }
    
    
    @MainActor
    func processVideo()  {
        guard self.processingState == .loaded else {
            return
        }
        self.processingState = .processing
        
        Task {
            var frameIndex = 0
            if let firstFrame = self.frames.first {
                frameIndex += 1
                do {
//                    let observations = try await vision.processHumanDetection(firstFrame)
//                    processObservations(observations, for: frameIndex)
                } catch (let error) {
                    print("error detecting: \(error.localizedDescription)")
                    self.error = .detectionFailed(message: error.localizedDescription)
                    return
                }
            }

            while true {
                guard let frameImage = videoManager.getNextFrame() else {
                    break
                }
                
                frameIndex += 1
                
//                do {
//                    let observations = try await vision.processHumanDetection(frameImage)
//                    processObservations(observations, for: frameIndex)
//                    self.frames.append(frameImage)
//                } catch (let error) {
//                    print("error detecting: \(error.localizedDescription)")
//                    self.error = .detectionFailed(message: error.localizedDescription)
//                    return
//                }
                
                // for testing
//                if frameIndex > 20 {
//                    break
//                }
            }
            
            self.processingState = .processed
            
            print("loading finishes: total frame: \(self.frames.count)")
            print("loading finishes: total object frame: \(self.trackedObjectsPerFrame.count)")
        }
        
    }
    
    
    @MainActor
    func reProcessVideo() {
        print("maxDisappearedFrameCount: \(tracker.maxDisappearedFrameCount)")
        
        self.processingState = .processing
        
        let loadedFrames = self.frames
        
        self.frames = []
        self.trackedObjectsPerFrame = []
        self.trackedObjects = []
        self.deregisteredObjects = []
        
        Task {
            for frameIndex in 0..<loadedFrames.count {
                let frameImage = loadedFrames[frameIndex]
                
                do {
//                    let observations = try await vision.processHumanDetection(frameImage)
//                    processObservations(observations, for: frameIndex)
//                    self.frames.append(frameImage)
                    
                } catch (let error) {
                    print("error detecting: \(error.localizedDescription)")
                    self.error = .detectionFailed(message: error.localizedDescription)
                    return
                }
                
                // for testing
//                if frameIndex > 20 {
//                    break
//                }

            }
            
            self.processingState = .processed
            print("loading finishes: total frame: \(self.frames.count)")
            print("loading finishes: total object frame: \(self.trackedObjectsPerFrame.count)")
        }

    }
    
    
    @MainActor
    func loadVideo(_ url: URL) {
    
        self.processingState = .loading
        
        guard url.startAccessingSecurityScopedResource() else {
            print("Fail to start Accessing Security Scoped. ")
            self.error = .loadingFailed(message: "Fail to start Accessing Security Scoped.")
            return
        }

        Task {
            do {
                try await videoManager.loadVideo(url)
            } catch(let error) {
                if let error = error as? TrackingError {
                    self.error = error
                } else {
                    self.error = .loadingFailed(message: "Unknown error while loading.")
                }
                return
            }
            
            print("load success")
            print("video duration: \(videoManager.duration ?? 0)")
            
//            if let firstFrame = videoManager.getNextFrame() {
//                self.frames = [firstFrame]
//                self.trackedObjectsPerFrame = []
//                self.trackedObjects = []
//                self.deregisteredObjects = []
//            } else {
//                self.error = .noFrameAvailable
//                return
//            }
            
            self.processingState = .loaded

        }
    }
    
    
    @MainActor
    func processFileImporterResult(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                self.error = .loadingFailed(message: "File Url not available.")
                return
            }
            loadVideo(url)
        case .failure(let error):
            print("failed to import file with error: \(error.localizedDescription).")
            self.error = .loadingFailed(message: "failed to import file with error: \(error.localizedDescription).")
            return

        }
    }

}
