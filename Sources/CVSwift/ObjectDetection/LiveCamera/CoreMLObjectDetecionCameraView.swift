//
//  CoreMLObjectDetecionCameraView.swift
//  CVSwift
//
//  Created by Alpay Calalli on 21.02.26.
//

import AVFoundation
import Vision
import CoreML
import SwiftUI

public struct CoreMLObjectDetecionCameraView: View {
   @StateObject private var cameraManager = CameraManager()
   
   @State private var observations: [ObjectDetectionObservation] = []
   
   private let cameraPosition: AVCaptureDevice.Position
   private let coreMLModel: VNCoreMLModel?
   
   public init(
      coreMLModel: VNCoreMLModel,
      cameraPosition: AVCaptureDevice.Position = .back
   ) {
      self.coreMLModel = coreMLModel
      self.cameraPosition = cameraPosition
   }
   
   public init(
      coreMLModelName: String,
      extension ext: String = "mlmodel",
      cameraPosition: AVCaptureDevice.Position = .back
   ) {
      self.coreMLModel = loadCoreMLModelFromURL(fileName: coreMLModelName, extension: ext)
      self.cameraPosition = cameraPosition
   }
      
   public var body: some View {
      CameraPreview(sessionLayer: cameraManager.getPreviewLayer())
         .overlay {
            GeometryReader { geometry in
               ForEach(observations) { observation in
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
                  let coreMLModel
            else { return }
            
            var result: [ObjectDetectionObservation] = []
            
            let request = VNCoreMLRequest(model: coreMLModel)
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
            do {
               try handler.perform([request])
               if let observations = request.results as? [VNRecognizedObjectObservation] {
                  for observation in observations {
                     guard let mainLabel = observation.labels.first else { continue }
                     result.append(
                        .init(
                           boundingBox: observation.boundingBox,
                           className: mainLabel.identifier,
                           confidence: observation.confidence
                        )
                     )
                  }
               }
            } catch {
               print("error", error.localizedDescription)
            }
            
            observations = result
         }
         .onAppear {
            cameraManager.startSession(position: cameraPosition)
         }
         .onDisappear { cameraManager.stopSession() }

   }
}
