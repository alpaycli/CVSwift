//
//  RoboflowObjectDetecionCameraView.swift
//  CVSwift
//
//  Created by Alpay Calalli on 23.02.26.
//

import AVFoundation
import Roboflow
import SwiftUI

public struct RoboflowObjectDetecionCameraView: View {
   @StateObject private var cameraManager = CameraManager()
   
   @State private var observations: [ObjectDetectionObservation] = []
   
   @State private var rfModel: RFModel?
   private let roboflowManager: RoboflowManager?
   private let modelId: String
   private let modelVersion: Int
   private let cameraPosition: AVCaptureDevice.Position
   
   
   // UI values
   private let boundingBoxPadding = 4.0

   
   public init(modelId: String, modelVersion: Int, apiKey: String, cameraPosition: AVCaptureDevice.Position = .back) {
      roboflowManager = RoboflowManager(apiKey: apiKey)
      self.modelId = modelId
      self.modelVersion = modelVersion
      self.cameraPosition = cameraPosition
   }

   public var body: some View {
      CameraView(cameraManager: cameraManager)
         .overlay {
            GeometryReader { geometry in
               ForEach(observations) { observation in
//                  let rect = viewRectConverted(fromNormalizedContentsRect: observation.boundingBox, viewRect: geometry.frame(in: .global))
                  let rect = observation.boundingBox
                  if rect != .zero {
                     RoundedRectangle(cornerRadius: 8)
                        .stroke(.black, style: .init(lineWidth: 4.0))
                        .frame(width: convertedSize(from: rect.size, in: geometry.size).width,
                               height: convertedSize(from: rect.size, in: geometry.size).height)
                        .position(convertedPosition(from: rect, in: geometry.size))
                  }
               }
            }
         }
         .onChange(of: cameraManager.currentBuffer) { newValue in
            guard let newValue,
                  let pixelBuffer = CMSampleBufferGetImageBuffer(newValue),
                  let rfModel
            else { return }
            
            Task {
               let response = await rfModel.detect(
                  pixelBuffer: pixelBuffer,
                  options: .init(
                     cameraPosition: cameraPosition,
                     orientation: cameraPosition == .back ? .up : .upMirrored,
                     confidenceThreshold: 0.3
                  )
               )
               if let predictions = response.0 as? [RFObjectDetectionPrediction], response.1 == nil {
                  var result: [ObjectDetectionObservation] = []
                  for prediction in predictions {
//                     let size = imageSize(from: pixelBuffer)
//                     let rect = prediction.visionBoundingBox(imageSize: size)
                     let rect = prediction.box
                     print("prediction.box", prediction.box)
                     
                     result.append(
                        .init(
                           boundingBox: rect,
                           className: prediction.className,
                           confidence: prediction.confidence
                        )
                     )
                  }
                  observations = result
               }
            }
         }
         .task {
            rfModel = try? await roboflowManager?.loadRoboflowModel(modelId: modelId, modelVersion: modelVersion)
         }
   }
}
