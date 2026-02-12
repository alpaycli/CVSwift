//
//  ObjectDetectionObservation.swift
//  CVSwift
//
//  Created by Alpay Calalli on 11.02.26.
//

import AVFoundation
import Foundation

public struct ObjectDetectionObservation: Identifiable, Hashable {
   public let trackId: Int              // NEW: Unique ID for this tracked object
   public let id: UUID = UUID()
   /// Normalized Rectangle coordinates of observation.
   public let boundingBox: CGRect
   /// Confidence value of observation. (0-1)
   public let className: String
   public let confidence: Float
   /// Time of observation, if it only comes from video input. On live video, it will return nil.
   public let time: CMTime?
   public let age: Int                  // NEW: How many frames this object has been tracked
   public let timeSinceUpdate: Int      // NEW: Frames since last detection match

   init(trackId: Int, boundingBox: CGRect, className: String, confidence: Float, time: CMTime?, age: Int, timeSinceUpdate: Int) {
      self.trackId = trackId
      self.boundingBox = boundingBox
      self.className = className
      self.confidence = confidence
      self.time = time
      self.age = age
      self.timeSinceUpdate = timeSinceUpdate
   }
   
   init(boundingBox: CGRect, className: String, confidence: Float, time: CMTime?) {
      self.boundingBox = boundingBox
      self.className = className
      self.confidence = confidence
      self.time = time
      
      self.trackId = 0
      self.age = 0
      self.timeSinceUpdate = 0
   }
}

import Roboflow
class ObjectTrackingManager {
    // Initialize ByteTrack tracker (do this once, keep it alive)
    private let tracker = ByteTracker(
        trackThreshold: 0.4,      // Lower threshold for ByteTrack recovery
        highThreshold: 0.5,       // High confidence detections
        matchThreshold: 0.7,      // IoU threshold (0.7 = 70% overlap)
        maxTimeLost: 30           // Remove tracks after 30 frames without detection
    )
    
    /// Process detections and return tracked objects
    func processFrame(predictions: [RFObjectDetectionPrediction],
                     pixelBuffer: CVPixelBuffer,
                     timestamp: CMTime) -> [ObjectDetectionObservation] {
        
        let size = imageSize(from: pixelBuffer)
        
        // Convert predictions to ByteTrack Detection format
        let detections = predictions.map { prediction -> Detection in
            let rect = prediction.visionBoundingBox(imageSize: size)
            
            // Convert class name to numeric ID (or use a lookup dict)
            let classId = classNameToId(prediction.className)
            
            return Detection(
                x: rect.origin.x,
                y: rect.origin.y,
                width: rect.size.width,
                height: rect.size.height,
                score: prediction.confidence,
                classId: classId
            )
        }
        
        // Update tracker with new detections
        let activeTracks = tracker.update(detections: detections)
        
        // Convert tracks back to your result format
        var trackedObjects: [ObjectDetectionObservation] = []
        for track in activeTracks {
            trackedObjects.append(
               ObjectDetectionObservation(
                    trackId: track.trackId,
                    boundingBox: track.bbox,
                    className: classIdToName(track.classId),
                    confidence: track.score,
                    time: timestamp,
                    age: track.age,
                    timeSinceUpdate: track.timeSinceUpdate
                )
            )
        }
        
        return trackedObjects
    }
    
    /// Helper: Convert class name to ID
    private func classNameToId(_ className: String) -> Int {
        // Option 1: Simple hash
        // return abs(className.hashValue) % 1000
        
        // Option 2: Use a dictionary (recommended)
        let classMap: [String: Int] = [
            "person": 0,
            "car": 1,
            "bicycle": 2,
            "dog": 3,
            "cat": 4
            // Add your classes here
        ]
        return classMap[className] ?? 0
    }
    
    /// Helper: Convert class ID back to name
    private func classIdToName(_ classId: Int?) -> String {
        guard let classId = classId else { return "unknown" }
        
        let classMap: [Int: String] = [
            0: "person",
            1: "car",
            2: "bicycle",
            3: "dog",
            4: "cat"
            // Add your classes here
        ]
        return classMap[classId] ?? "unknown"
    }
    
    /// Reset tracker (call when starting new video or changing scene)
    func reset() {
        tracker.reset()
    }
    
    // Placeholder for imageSize function if you don't have it
    private func imageSize(from pixelBuffer: CVPixelBuffer) -> CGSize {
        return CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
    }
}
