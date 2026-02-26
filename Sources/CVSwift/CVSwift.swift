// The Swift Programming Language
// https://docs.swift.org/swift-book

import Vision

func loadCoreMLModelFromURL(fileName: String, extension ext: String = "mlmodel") -> VNCoreMLModel? {
   guard let modelURL = Bundle.main.url(forResource: fileName, withExtension: ext) else {
      print("Model file not found")
      return nil
   }

   do {
      let mlModel = try MLModel(contentsOf: modelURL)
      return try VNCoreMLModel(for: mlModel)
   } catch {
      print("Error creating VNCoreMLModel: \(error)")
      return nil
   }
}

import SwiftUI

func convertRect(
    _ rect: CGRect,
    geo: GeometryProxy,
    videoSize: CGSize
) -> CGRect {

    let videoRect = videoRect(
        videoSize: videoSize,
        containerSize: geo.size
    )

    let width  = rect.width  * videoRect.width
    let height = rect.height * videoRect.height

    let x = videoRect.minX + rect.minX * videoRect.width
    let y = videoRect.minY + (1 - rect.minY - rect.height) * videoRect.height

    return CGRect(x: x, y: y, width: width, height: height)
}

func videoRect(
    videoSize: CGSize,
    containerSize: CGSize
) -> CGRect {

    let videoAspect = videoSize.width / videoSize.height
    let containerAspect = containerSize.width / containerSize.height

    if videoAspect > containerAspect {
        // letterboxed top & bottom
        let width = containerSize.width
        let height = width / videoAspect
        let y = (containerSize.height - height) / 2
        return CGRect(x: 0, y: y, width: width, height: height)
    } else {
        // letterboxed left & right
        let height = containerSize.height
        let width = height * videoAspect
        let x = (containerSize.width - width) / 2
        return CGRect(x: x, y: 0, width: width, height: height)
    }
}

/// Converts a normalized Vision point to a SwiftUI point
func convertedPosition(from normalizedRect: CGRect, in viewSize: CGSize) -> CGPoint {
    // 1. Scale x and y
    let scaledX = normalizedRect.midX * viewSize.width
    // 2. Flip y: subtract the scaled y from the total height to flip the origin
    let scaledY = (1 - normalizedRect.midY) * viewSize.height
    return CGPoint(x: scaledX, y: scaledY)
}

/// Converts a normalized Vision size to a SwiftUI size
func convertedSize(from normalizedSize: CGSize, in viewSize: CGSize) -> CGSize {
    // Only scaling is needed for width and height
    let scaledWidth = normalizedSize.width * viewSize.width
    let scaledHeight = normalizedSize.height * viewSize.height
    return CGSize(width: scaledWidth, height: scaledHeight)
}


func viewRectConverted(from normalizedRect: CGRect, in viewRect: CGRect) -> CGRect {
   let videoRect = viewRect
   let origin = CGPoint(x: videoRect.origin.x + normalizedRect.origin.x * videoRect.width,
                        y: videoRect.origin.y + normalizedRect.origin.y * videoRect.height)
   let size = CGSize(width: normalizedRect.width * videoRect.width,
                     height: normalizedRect.height * videoRect.height)
   let convertedRect = CGRect(origin: origin, size: size)
   return convertedRect.integral
}

func viewRectConverted2(fromNormalizedContentsRect normalizedRect: CGRect, viewRect: CGRect) -> CGRect {
    let flippedY = 1 - normalizedRect.origin.y - normalizedRect.height // <-- flip Y
    return CGRect(
        x: normalizedRect.origin.x * viewRect.width + viewRect.minX,
        y: flippedY * viewRect.height + viewRect.minY,
        width: normalizedRect.width * viewRect.width,
        height: normalizedRect.height * viewRect.height
    )
}
