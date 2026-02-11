//
//  VideoObjectDetector.swift
//  CVSwift
//
//  Created by Alpay Calalli on 11.02.26.
//

import Vision
import AVFoundation
import Roboflow
import Foundation

public class VideoObjectDetector {
   private let videoManager = VideoManager()
   
   public func processRoboflowModel(modelId: String, modelVersion: Int, videoURL: URL) async throws -> [ObjectDetectionObservation] {
      return []
   }
   
   public func processRoboflowModel(_ rfModel: RFModel, videoURL: URL) async throws -> [ObjectDetectionObservation] {
      try await videoManager.loadVideo(videoURL)
      
      var result: [ObjectDetectionObservation] = []
      
      while let buffer = videoManager.getNextFrame() {
         guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { continue }
         let response = await rfModel.detect(pixelBuffer: pixelBuffer)
         if let predictions = response.0 as? [RFObjectDetectionPrediction], response.1 == nil {
            for prediction in predictions {
               let size = imageSize(from: pixelBuffer)
               let rect = prediction.visionBoundingBox(imageSize: size)
               
               result.append(
                  .init(
                     boundingBox: rect,
                     className: prediction.className,
                     confidence: prediction.confidence,
                     time: buffer.presentationTimeStamp
                  )
               )
            }
         }
      }
      
      return result
   }
   
   public func processCoreMLModel(_ request: VNCoreMLRequest, videoURL: URL) async throws -> [ObjectDetectionObservation] {
      try await videoManager.loadVideo(videoURL)
      
      var result: [ObjectDetectionObservation] = []
      
      while let buffer = videoManager.getNextFrame() {
         guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { continue }
         let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
         try handler.perform([request])
         if let observations = request.results as? [VNRecognizedObjectObservation] {
            for observation in observations {
               guard let mainLabel = observation.labels.first else { continue }
               result.append(
                  .init(
                     boundingBox: observation.boundingBox,
                     className: mainLabel.identifier,
                     confidence: observation.confidence,
                     time: buffer.presentationTimeStamp
                  )
               )
            }
         }
      }
      
      return result
   }
}
