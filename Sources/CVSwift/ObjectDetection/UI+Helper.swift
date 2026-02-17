//
//  File.swift
//  CVSwift
//
//  Created by Alpay Calalli on 17.02.26.
//

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
