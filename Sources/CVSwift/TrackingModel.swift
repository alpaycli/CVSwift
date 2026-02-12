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

import Foundation
import Accelerate

// MARK: - Detection Class
/// Represents a single object detection with bounding box and confidence score
struct Detection {
    let bbox: CGRect  // (x, y, width, height)
    let score: Float
    let classId: Int?
    
    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, score: Float, classId: Int? = nil) {
        self.bbox = CGRect(x: x, y: y, width: width, height: height)
        self.score = score
        self.classId = classId
    }
    
    /// Convert to center format (cx, cy, w, h)
    var centerFormat: [CGFloat] {
        return [
            bbox.midX,
            bbox.midY,
            bbox.width,
            bbox.height
        ]
    }
}

// MARK: - Kalman Filter
/// Simple Kalman filter for tracking object state
class KalmanFilter {
    private var state: [CGFloat]  // [cx, cy, w, h, vx, vy, vw, vh]
    private var covariance: [[CGFloat]]
    
    private let processNoise: CGFloat = 0.01
    private let measurementNoise: CGFloat = 0.1
    
    init(initialState: [CGFloat]) {
        // State: [cx, cy, w, h, vx, vy, vw, vh]
        self.state = initialState + [0, 0, 0, 0]
        
        // Initialize covariance matrix
        self.covariance = Array(repeating: Array(repeating: 0.0, count: 8), count: 8)
        for i in 0..<8 {
            covariance[i][i] = i < 4 ? 10.0 : 100.0
        }
    }
    
    /// Predict next state
    func predict() -> [CGFloat] {
        // State transition: position += velocity
        state[0] += state[4]  // cx += vx
        state[1] += state[5]  // cy += vy
        state[2] += state[6]  // w += vw
        state[3] += state[7]  // h += vh
        
        // Update covariance (simplified)
        for i in 0..<8 {
            covariance[i][i] += processNoise
        }
        
        return Array(state[0..<4])
    }
    
    /// Update state with measurement
    func update(measurement: [CGFloat]) {
        // Kalman gain calculation (simplified)
        let gain = measurementNoise / (measurementNoise + covariance[0][0])
        
        // Update state
        for i in 0..<4 {
            let innovation = measurement[i] - state[i]
            state[i] += gain * innovation
            
            // Update velocity estimate
            if i < 4 {
                state[i + 4] = 0.9 * state[i + 4] + 0.1 * innovation
            }
        }
        
        // Update covariance (simplified)
        for i in 0..<4 {
            covariance[i][i] *= (1 - gain)
        }
    }
    
    func getState() -> [CGFloat] {
        return Array(state[0..<4])
    }
}

// MARK: - Track Class
/// Represents a tracked object over time
class Track {
   
   nonisolated(unsafe) static var nextId: Int = 1
    
    let trackId: Int
    var kalmanFilter: KalmanFilter
    var bbox: CGRect
    var score: Float
    var classId: Int?
    
    var age: Int = 0
    var timeSinceUpdate: Int = 0
    var hitStreak: Int = 0
    var state: TrackState = .tentative
    
    enum TrackState {
        case tentative
        case confirmed
        case lost
    }
    
    init(detection: Detection) {
        self.trackId = Track.nextId
        Track.nextId += 1
        
        self.kalmanFilter = KalmanFilter(initialState: detection.centerFormat)
        self.bbox = detection.bbox
        self.score = detection.score
        self.classId = detection.classId
    }
    
    /// Predict next position
    func predict() {
        age += 1
        timeSinceUpdate += 1
        
        let predictedState = kalmanFilter.predict()
        updateBBox(from: predictedState)
    }
    
    /// Update with matched detection
    func update(detection: Detection) {
        timeSinceUpdate = 0
        hitStreak += 1
        
        kalmanFilter.update(measurement: detection.centerFormat)
        let updatedState = kalmanFilter.getState()
        updateBBox(from: updatedState)
        
        self.score = detection.score
        
        // Activate track after minimum hits
        if hitStreak >= 3 && state == .tentative {
            state = .confirmed
        }
    }
    
    /// Mark as lost
    func markLost() {
        state = .lost
    }
    
    private func updateBBox(from centerFormat: [CGFloat]) {
        let cx = centerFormat[0]
        let cy = centerFormat[1]
        let w = centerFormat[2]
        let h = centerFormat[3]
        
        self.bbox = CGRect(
            x: cx - w/2,
            y: cy - h/2,
            width: w,
            height: h
        )
    }
}

// MARK: - IoU Calculation
/// Calculate Intersection over Union between two bounding boxes
func calculateIoU(_ bbox1: CGRect, _ bbox2: CGRect) -> CGFloat {
    let intersection = bbox1.intersection(bbox2)
    
    if intersection.isNull {
        return 0.0
    }
    
    let intersectionArea = intersection.width * intersection.height
    let union = bbox1.width * bbox1.height + bbox2.width * bbox2.height - intersectionArea
    
    return union > 0 ? intersectionArea / union : 0
}

/// Calculate IoU distance matrix
func calculateIoUMatrix(tracks: [Track], detections: [Detection]) -> [[CGFloat]] {
    var matrix: [[CGFloat]] = []
    
    for track in tracks {
        var row: [CGFloat] = []
        for detection in detections {
            let iou = calculateIoU(track.bbox, detection.bbox)
            row.append(1.0 - iou)  // Convert to distance
        }
        matrix.append(row)
    }
    
    return matrix
}

// MARK: - Hungarian Algorithm (Linear Assignment)
/// Simple greedy matching as a substitute for Hungarian algorithm
func linearAssignment(costMatrix: [[CGFloat]], threshold: CGFloat) -> (matches: [(Int, Int)], unmatchedTracks: [Int], unmatchedDetections: [Int]) {
    var matches: [(Int, Int)] = []
    var matchedTracks = Set<Int>()
    var matchedDetections = Set<Int>()
    
    if costMatrix.isEmpty {
        return ([], Array(0..<0), Array(0..<0))
    }
    
    let numTracks = costMatrix.count
    let numDetections = costMatrix[0].count
    
    // Create list of all possible matches with their costs
    var candidates: [(trackIdx: Int, detIdx: Int, cost: CGFloat)] = []
    for i in 0..<numTracks {
        for j in 0..<numDetections {
            if costMatrix[i][j] < threshold {
                candidates.append((i, j, costMatrix[i][j]))
            }
        }
    }
    
    // Sort by cost (ascending)
    candidates.sort { $0.cost < $1.cost }
    
    // Greedily assign matches
    for candidate in candidates {
        if !matchedTracks.contains(candidate.trackIdx) && !matchedDetections.contains(candidate.detIdx) {
            matches.append((candidate.trackIdx, candidate.detIdx))
            matchedTracks.insert(candidate.trackIdx)
            matchedDetections.insert(candidate.detIdx)
        }
    }
    
    let unmatchedTracks = (0..<numTracks).filter { !matchedTracks.contains($0) }
    let unmatchedDetections = (0..<numDetections).filter { !matchedDetections.contains($0) }
    
    return (matches, unmatchedTracks, unmatchedDetections)
}

// MARK: - ByteTrack Tracker
/// Main ByteTrack tracker class
class ByteTracker {
    private var tracks: [Track] = []
    private var frameCount: Int = 0
    
    // ByteTrack parameters
    private let trackThreshold: Float       // High threshold for track initialization
    private let highThreshold: Float        // High threshold for first association
    private let matchThreshold: CGFloat     // IoU threshold for matching
    private let maxTimeLost: Int           // Maximum frames before removing track
    
    init(
        trackThreshold: Float = 0.5,
        highThreshold: Float = 0.6,
        matchThreshold: CGFloat = 0.8,
        maxTimeLost: Int = 30
    ) {
        self.trackThreshold = trackThreshold
        self.highThreshold = highThreshold
        self.matchThreshold = matchThreshold
        self.maxTimeLost = maxTimeLost
    }
    
    /// Update tracker with new detections
    func update(detections: [Detection]) -> [Track] {
        frameCount += 1
        
        // Separate detections by score
        let highDetections = detections.filter { $0.score >= highThreshold }
        let lowDetections = detections.filter { $0.score >= trackThreshold && $0.score < highThreshold }
        
        // Predict all tracks
        for track in tracks {
            track.predict()
        }
        
        // Split tracks into confirmed and unconfirmed
        let confirmedTracks = tracks.filter { $0.state == .confirmed }
        let unconfirmedTracks = tracks.filter { $0.state == .tentative }
        
        // First association: confirmed tracks with high detections
        let (matches1, unmatchedTracks1, unmatchedDets1) = associateDetections(
            tracks: confirmedTracks,
            detections: highDetections,
            threshold: matchThreshold
        )
        
        // Update matched tracks
        for (trackIdx, detIdx) in matches1 {
            confirmedTracks[trackIdx].update(detection: highDetections[detIdx])
        }
        
        // Second association: unmatched confirmed tracks with low detections
        let unmatchedConfirmedTracks = unmatchedTracks1.map { confirmedTracks[$0] }
        let (matches2, unmatchedTracks2, _) = associateDetections(
            tracks: unmatchedConfirmedTracks,
            detections: lowDetections,
            threshold: matchThreshold
        )
        
        // Update matched tracks from second association
        for (trackIdx, detIdx) in matches2 {
            unmatchedConfirmedTracks[trackIdx].update(detection: lowDetections[detIdx])
        }
        
        // Mark lost tracks
        for trackIdx in unmatchedTracks2 {
            unmatchedConfirmedTracks[trackIdx].markLost()
        }
        
        // Third association: unconfirmed tracks with remaining high detections
        let remainingHighDets = unmatchedDets1.map { highDetections[$0] }
        let (matches3, unmatchedTracks3, unmatchedDets3) = associateDetections(
            tracks: unconfirmedTracks,
            detections: remainingHighDets,
            threshold: matchThreshold
        )
        
        // Update unconfirmed tracks
        for (trackIdx, detIdx) in matches3 {
            unconfirmedTracks[trackIdx].update(detection: remainingHighDets[detIdx])
        }
        
        // Remove unmatched unconfirmed tracks
        for trackIdx in unmatchedTracks3 {
            unconfirmedTracks[trackIdx].markLost()
        }
        
        // Initialize new tracks with unmatched high detections
        for detIdx in unmatchedDets3 {
            let newTrack = Track(detection: remainingHighDets[detIdx])
            tracks.append(newTrack)
        }
        
        // Remove tracks that have been lost too long
        tracks.removeAll { track in
            track.timeSinceUpdate > maxTimeLost || track.state == .lost
        }
        
        // Return active tracks
        return tracks.filter { $0.state == .confirmed }
    }
    
    /// Associate detections to tracks
    private func associateDetections(
        tracks: [Track],
        detections: [Detection],
        threshold: CGFloat
    ) -> (matches: [(Int, Int)], unmatchedTracks: [Int], unmatchedDetections: [Int]) {
        if tracks.isEmpty || detections.isEmpty {
            return ([], Array(0..<tracks.count), Array(0..<detections.count))
        }
        
        let costMatrix = calculateIoUMatrix(tracks: tracks, detections: detections)
        return linearAssignment(costMatrix: costMatrix, threshold: 1.0 - threshold)
    }
    
    /// Get all current tracks
    func getTracks() -> [Track] {
        return tracks.filter { $0.state == .confirmed }
    }
    
    /// Reset tracker
    func reset() {
        tracks.removeAll()
        frameCount = 0
        Track.nextId = 1
    }
}

// MARK: - Usage Example
/*
// Example usage:
let tracker = ByteTracker(
    trackThreshold: 0.5,
    highThreshold: 0.6,
    matchThreshold: 0.8,
    maxTimeLost: 30
)

// For each frame:
let detections = [
    Detection(x: 100, y: 100, width: 50, height: 50, score: 0.9, classId: 0),
    Detection(x: 200, y: 150, width: 60, height: 70, score: 0.85, classId: 0),
    Detection(x: 300, y: 200, width: 55, height: 65, score: 0.4, classId: 1)
]

let activeTracks = tracker.update(detections: detections)

// Access tracked objects
for track in activeTracks {
    print("Track ID: \(track.trackId)")
    print("BBox: \(track.bbox)")
    print("Score: \(track.score)")
    print("Age: \(track.age)")
}
*/
