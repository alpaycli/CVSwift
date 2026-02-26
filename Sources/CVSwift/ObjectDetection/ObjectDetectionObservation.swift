//
//  ObjectDetectionObservation.swift
//  CVSwift
//
//  Created by Alpay Calalli on 11.02.26.
//

import AVFoundation
import Foundation

public struct ObjectDetectionObservation: Identifiable, Hashable {
   public let id: UUID = UUID()
   /// Normalized Rectangle coordinates of observation.
   public let boundingBox: CGRect
   public let className: String
   /// Confidence score of observation. (0-1)
   public let confidence: Float
   /// Time of observation, if it only comes from video input. On live video, it will return nil.
   public let time: CMTime?
   
   init(boundingBox: CGRect, className: String, confidence: Float, time: CMTime? = nil) {
      self.boundingBox = boundingBox
      self.className = className
      self.confidence = confidence
      self.time = time
   }
}
