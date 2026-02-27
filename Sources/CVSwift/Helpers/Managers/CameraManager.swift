//
//  CameraManager.swift
//  CVSwift
//
//  Created by Alpay Calalli on 23.02.26.
//

import AVFoundation
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

class CameraManager: NSObject, ObservableObject {
   // AVFoundation Components
   private let session = AVCaptureSession()
   private let output = AVCapturePhotoOutput()
   private var previewLayer: AVCaptureVideoPreviewLayer?
   private let videoOutput = AVCaptureVideoDataOutput()
   private let videoOutputQueue = DispatchQueue(label: "VideoOutputQueue")
   
   // Published property for SwiftUI binding
   #if canImport(UIKit)
   @Published var capturedImage: UIImage?
   #else
   @Published var capturedImage: NSImage?
   #endif
   @Published var currentBuffer: CMSampleBuffer?
   
   func startSession(position: AVCaptureDevice.Position) {
      configureSession(position: position)
   }
   
   // ← ADD: extracted so it's reusable for switching
   private func configureSession(position: AVCaptureDevice.Position) {
      guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input),
            session.canAddOutput(output),
            session.canAddOutput(videoOutput)
      else { return }
      
      videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
      videoOutput.alwaysDiscardsLateVideoFrames = true
      
      session.beginConfiguration()
      
      // Remove existing inputs before adding new one
      session.inputs.forEach { session.removeInput($0) }
      
      session.addInput(input)
      session.addOutput(output)
      session.addOutput(videoOutput)
      videoOutput.videoSettings = [
         kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
      ]
      session.commitConfiguration()
      
      if let connection = videoOutput.connection(with: .video) {
         if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
         }
         if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = (position == .front)
         }
      }
      
      if !session.isRunning {
         DispatchQueue.global().async { self.session.startRunning() }
      }
   }
   
   // Lifecycle Management
   func stopSession() {
      session.stopRunning()
      
      session.beginConfiguration()
      session.inputs.forEach { session.removeInput($0) }
      session.outputs.forEach { session.removeOutput($0) }
      session.commitConfiguration()
      
      previewLayer = nil
      capturedImage = nil
      currentBuffer = nil
   }
   
   // Preview Layer Management
   func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
      if let layer = previewLayer {
         return layer
      } else {
         let layer = AVCaptureVideoPreviewLayer(session: session)
         layer.videoGravity = .resizeAspect
         previewLayer = layer
         return layer
      }
   }
}

// MARK: - Buffer Delegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
   func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
      // Called on videoOutputQueue for every frame
      guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
      DispatchQueue.main.async {
         self.currentBuffer = sampleBuffer
      }
   }
   
   func captureOutput(_ output: AVCaptureOutput,
                      didDrop sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
      // Called when a frame is dropped due to late delivery
      print("Frame dropped")
   }
}
