//
//  TrackingModel.swift
//  CVSwift
//
//  Created by Alpay Calalli on 11.02.26.
//

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
