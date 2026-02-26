// Currently, camera capabilities only support iOS, not macOS

import AVFoundation
import SwiftUI
#if canImport(UIKit)
import UIKit

@available(iOS 13.0, *)
struct CameraPreview: UIViewRepresentable {
   let sessionLayer: AVCaptureVideoPreviewLayer
   
   func makeUIView(context: Context) -> UIView {
      let view = UIView()
      sessionLayer.videoGravity = .resizeAspectFill
      view.layer.addSublayer(sessionLayer)
      return view
   }
   
   func updateUIView(_ uiView: UIView, context: Context) {
      DispatchQueue.main.async {
         sessionLayer.frame = uiView.bounds
      }
   }
}
#endif
