import SwiftUI
import AVKit

extension SplashView {
    struct Geometry {
        let topFrame: CGRect
        let bottomFrame: CGRect

        init(viewport: CGSize) {
            let letterRelativeWidth: CGFloat = 187
            let letterRelativeHeigth: CGFloat = 245
            let letterRelativePadding: CGFloat = 1
            let top = CGSize(
                width: [
                    letterRelativeWidth,
                    letterRelativePadding,
                    letterRelativeWidth
                ].reduce(0, +),
                height: letterRelativeHeigth
            )
            let bottom = CGSize(
                width: [
                    letterRelativeWidth,
                    letterRelativePadding,
                    letterRelativeWidth
                ].reduce(0, +),
                height: [
                    letterRelativeHeigth,
                    letterRelativePadding,
                    letterRelativeHeigth
                ].reduce(0, +)
            )
            let all = CGSize(
                width: top.width,
                height: top.height + letterRelativePadding + bottom.height
            )
            let contentFrame = AVMakeRect(
                aspectRatio: all,
                insideRect: CGRect(
                    origin: .zero,
                    size: viewport
                )
            )
            let xScale = contentFrame.width / all.width
            let yScale = contentFrame.height / all.height
            topFrame = CGRect(
                x: contentFrame.minX + top.width / 2 * xScale,
                y: contentFrame.minY + top.height / 2 * yScale,
                width: top.width * xScale,
                height: top.height * yScale
            )
            bottomFrame = CGRect(
                x: topFrame.minX,
                y: topFrame.maxY + top.height / 2 * yScale,
                width: bottom.width * xScale,
                height: bottom.height * yScale
            )
        }
    }
}
