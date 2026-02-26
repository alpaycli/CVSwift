//
//  CoreMLObjectDetecionCameraView.swift
//  CVSwift
//
//  Created by Alpay Calalli on 21.02.26.
//

import Vision
import CoreML
import SwiftUI

public struct CoreMLObjectDetecionCameraView: View {
   @StateObject private var cameraManager = CameraManager()
   
   @State private var observations: [ObjectDetectionObservation] = []
   
   private let coreMLModel: VNCoreMLModel?
   
   public init(coreMLModel: VNCoreMLModel) {
      self.coreMLModel = coreMLModel
   }
   
   public init(coreMLModelName: String, extension ext: String = "mlmodel") {
      self.coreMLModel = loadCoreMLModelFromURL(fileName: coreMLModelName, extension: ext)
   }
      
   public var body: some View {
      CameraView(cameraManager: cameraManager)
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
               print(request.results)
               if let observations = request.results as? [VNRecognizedObjectObservation] {
                  print("results", observations.map(\.boundingBox))
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
   }
}
