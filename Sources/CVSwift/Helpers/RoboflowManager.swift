//
//  RoboflowManager.swift
//  CVSwift
//
//  Created by Alpay Calalli on 12.02.26.
//

import Roboflow
import Foundation

class RoboflowManager {
   private let rf: RoboflowMobile
   //   private let modelId = "basketball-players-vi5zp"
//   private let modelId = "car-plate-xxwpo"
//   private let ocrModelId = "ocr-oy9a7"
//   private let modelVersion = 1
   private var model: RFModel?
   private var isModelLoaded = false
   private var isProcessingFrame = false
      
   init(apiKey: String) {
      self.rf = .init(apiKey: apiKey)
   }
   
   func loadRoboflowModel(modelId: String, modelVersion: Int) async throws -> RFModel {
      let (loadedModel, error, _, _) = await rf.load(model: modelId, modelVersion: modelVersion)
      if let error { throw error }
      guard let loadedModel else { throw URLError(.badURL) }
//      loadedModel.configure(threshold: 0.5, overlap: 0.5, maxObjects: 1)
      self.model = loadedModel
      isModelLoaded = true
      
      return loadedModel
   }
   
   
}
