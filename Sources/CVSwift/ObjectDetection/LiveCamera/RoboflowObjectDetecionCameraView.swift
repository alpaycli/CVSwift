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
   
   public init(modelId: String, modelVersion: Int, apiKey: String, cameraPosition: AVCaptureDevice.Position = .back) {
      roboflowManager = RoboflowManager(apiKey: apiKey)
      self.modelId = modelId
      self.modelVersion = modelVersion
      self.cameraPosition = cameraPosition
   }

   public var body: some View {
      CameraPreview(sessionLayer: cameraManager.getPreviewLayer())
         .overlay {
            GeometryReader { geometry in
               ForEach(observations) { observation in
                  let rect = observation.boundingBox
                  let width = convertedSize(from: rect.size, in: geometry.size).width
                  if rect != .zero {
                     VStack(alignment: .trailing, spacing: 4){
                        Text(observation.className)
                           .font(.system(size: width / 8, weight: .bold))
                        RoundedRectangle(cornerRadius: 8)
                           .stroke(.black, style: .init(lineWidth: 2.0))
                     }
                     .frame(width: width,
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
                     let rect = prediction.box
                     
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
            cameraManager.startSession(position: cameraPosition)
         }
         .onDisappear { cameraManager.stopSession() }

   }
}
