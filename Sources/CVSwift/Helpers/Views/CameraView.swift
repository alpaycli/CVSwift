//
//  CameraView.swift
//  CVSwift
//
//  Created by Alpay Calalli on 23.02.26.
//

import Combine
import SwiftUI

@available(iOS 13.0, *)
struct CameraView: View {
   @ObservedObject var cameraManager: CameraManager
   @Environment(\.presentationMode) var presentationMode
      
   var body: some View {
      ZStack {
         GeometryReader { _ in
            CameraPreview(sessionLayer: cameraManager.getPreviewLayer())
         }
      }
      .onAppear {
         cameraManager.startSession()
      }
      .onDisappear { cameraManager.stopSession() }
   }
}
