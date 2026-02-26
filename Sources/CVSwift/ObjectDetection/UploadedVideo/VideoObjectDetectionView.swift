//
//  VideoObjectDetectionView.swift
//  CVSwift
//
//  Created by Alpay Calalli on 17.02.26.
//

import AVKit
import SwiftUI

public struct VideoObjectDetectionView: View {
   @State private var observer: Any?
   @State private var player: AVPlayer?
   /// Filtered observations to show for the current timestamp of the video.
   @State private var currentObservations: [ObjectDetectionObservation] = []
   
   private let videoURL: URL
   private let observations: [ObjectDetectionObservation]
   
   public init(
      videoURL: URL,
      observations: [ObjectDetectionObservation]
   ) {
      self.videoURL = videoURL
      self.observations = observations
   }
    public var body: some View {
       VStack {
          Text(observations.count.formatted())
          VideoPlayer(player: player) {
             GeometryReader { geo in
                ForEach(currentObservations) { observation in
                   if let videoSize = player?.currentItem?.presentationSize {
                      let rect = observation.boundingBox
                      let convertedRect = convertRect(rect, geo: geo, videoSize: videoSize)
                      Rectangle()
                         .stroke(.red, lineWidth: 2)
                         .frame(
                           width: max(0, convertedRect.width),
                            height: max(0, convertedRect.height)
                         )
                         .position(
                            x: convertedRect.midX,
                            y: convertedRect.midY
                         )
                      
                   }
                }
             }
          }
       }
       .task(id: observations) {
          player = .init(url: videoURL)
          
          guard !observations.isEmpty else { return }
          observer = player?.addPeriodicTimeObserver(
              forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
              queue: .main
          ) { currentTime in
              
              let currentSeconds = currentTime.seconds
              let tolerance: Double = 0.05   // 50ms
              
              currentObservations = observations
                .filter { abs($0.time!.seconds - currentSeconds) <= tolerance }
          }
       }
       .onDisappear { observer = nil }
    }
}

#Preview {
   VideoObjectDetectionView(videoURL: .init(string: "")!, observations: [])
}
