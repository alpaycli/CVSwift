//
//  VideoManager.swift
//  ItsukiAnalyzer
//
//  Created by Itsuki on 2024/08/11.
//

import AVFoundation
import SwiftUI

class VideoManager {
    
    // MARK: For reading video
    private var videoAsset: AVURLAsset?
    private var videoTrack: AVAssetTrack?
    private var assetReader: AVAssetReader?
    private var videoAssetReaderOutput: AVAssetReaderTrackOutput?
    
    
    // MARK: video properties
    // frames per second
    var frameRate: Float32?
    
    // Indicates the minimum duration of the track's frames
    var minFrameDuration: Float64? {
        if let cmMinFrameDuration = cmMinFrameDuration {
            return CMTimeGetSeconds(cmMinFrameDuration)
        }
        return nil
    }
    var cmMinFrameDuration: CMTime?
        
    // transform specified in the track's storage container as the preferred transformation of the visual media data for display purposes: Value returned is often but not always `.identity`
    var affineTransform: CGAffineTransform!
    
    var duration: Float64?

    
    // MARK: Functions For reading video from URL
    func loadVideo(_ url: URL) async throws {
        self.videoAsset = AVURLAsset(url: url)
        let tracks = try? await self.videoAsset?.loadTracks(withMediaType: AVMediaType.video)

        if let videoTrack = tracks?.first {
            self.videoTrack = videoTrack
            do {
                let (affineTransform, metadata, cmMinFrameDuration, frameRate) = try await self.videoTrack!.load(.preferredTransform, .metadata, .minFrameDuration, .nominalFrameRate)
                self.affineTransform = affineTransform
                self.cmMinFrameDuration = cmMinFrameDuration
                self.frameRate = frameRate
                let duration = try await self.videoAsset!.load(.duration)
                self.duration = CMTimeGetSeconds(duration)
                
            } catch (let error) {
                print("error loading data: \(error.localizedDescription).")
                throw TrackingError.loadingFailed(message: "error loading data: \(error.localizedDescription).")
            }

        } else {
            print("error loading tracks.")
            throw TrackingError.loadingFailed(message: "error loading track.")
        }
        
        try self.readAsset()
        
        return
    }
    
    
    private func readAsset() throws {
        guard self.videoAsset != nil, self.videoTrack != nil else {
            print("nil video asset or video track")
            throw TrackingError.loadingFailed(message: "nil video reader output")
        }
        
        do {
            self.assetReader = try AVAssetReader(asset: videoAsset!)
        } catch(let error) {
            print("Failed to create AVAssetReader object: \(error.localizedDescription).")
            throw TrackingError.loadingFailed(message: "Failed to create AVAssetReader object: \(error.localizedDescription).")
        }
        
        self.videoAssetReaderOutput = AVAssetReaderTrackOutput(track: videoTrack!, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange])
        guard self.videoAssetReaderOutput != nil else {
            print("nil video reader output.")
            throw TrackingError.loadingFailed(message: "nil video reader output.")
        }

        self.videoAssetReaderOutput!.alwaysCopiesSampleData = true
        guard self.assetReader!.canAdd(videoAssetReaderOutput!) else {
            print("cannot add output.")
            throw TrackingError.loadingFailed(message: "cannot add output.")
        }
        
        self.assetReader!.add(videoAssetReaderOutput!)
        guard self.assetReader!.startReading() else {
            print("Fail to start reading video.")
            throw TrackingError.loadingFailed(message: "Fail to start reading video.")
        }
    }
    

//    func getNextFrame() -> CGImage? {
//        guard self.videoAssetReaderOutput != nil else { return nil }
//        guard let sampleBuffer = self.videoAssetReaderOutput!.copyNextSampleBuffer(), let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//            return nil
//        }
//        return CIImage(cvImageBuffer: imageBuffer).transformed(by: self.affineTransform ?? .identity).cgImage
//    }
   
   func getNextFrame() -> CMSampleBuffer? {
      guard self.videoAssetReaderOutput != nil else { return nil }
      guard let sampleBuffer = self.videoAssetReaderOutput!.copyNextSampleBuffer(), let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
         return nil
      }
      return sampleBuffer
   }
    
}

