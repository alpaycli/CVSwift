//
//  RoboflowHelpers.swift
//  CarTrafficAnalyzer-iOS
//
//  Created by Alpay Calalli on 05.02.26.
//

import Roboflow
import CoreGraphics
import AVKit

private func normalizedRectFromCenterBased(
   centerX: CGFloat,
   centerY: CGFloat,
   width: CGFloat,
   height: CGFloat,
   imageSize: CGSize
) -> CGRect {
   let minX = centerX - width / 2
   let minY = centerY - height / 2
   
   return CGRect(
      x: minX / imageSize.width,
      y: minY / imageSize.height,
      width: width / imageSize.width,
      height: height / imageSize.height
   )
}


func imageSize(from pixelBuffer: CVPixelBuffer) -> CGSize {
 CGSize(
     width: CVPixelBufferGetWidth(pixelBuffer),
     height: CVPixelBufferGetHeight(pixelBuffer)
 )
}

extension RFObjectDetectionPrediction {

 /// Vision-style normalized rect (bottom-left origin)
 func visionBoundingBox(imageSize: CGSize) -> CGRect {
     let rect = normalizedBoundingBox(imageSize: imageSize)

     return CGRect(
         x: rect.minX,
         y: 1 - rect.minY - rect.height,
         width: rect.width,
         height: rect.height
     )
 }


}

extension RFObjectDetectionPrediction {

 /// Converts center-based pixel bounding box to normalized CGRect (top-left origin)
 func normalizedBoundingBox(imageSize: CGSize) -> CGRect {
     let centerX = CGFloat(self.x)
     let centerY = CGFloat(self.y)
     let width   = CGFloat(self.width)
     let height  = CGFloat(self.height)

     let minX = centerX - width / 2
     let minY = centerY - height / 2

     return CGRect(
         x: minX / imageSize.width,
         y: minY / imageSize.height,
         width: width / imageSize.width,
         height: height / imageSize.height
     )
 }
}

