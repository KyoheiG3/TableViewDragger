//
//  UIScrollViewExtension.swift
//  Pods
//
//  Created by Kyohei Ito on 2015/09/29.
//
//

import UIKit

extension UIScrollView {
    enum DraggingDirection {
        case up
        case down
    }

    func preferredContentOffset(at point: CGPoint, velocity: CGFloat) -> CGPoint {
        let distance = ScrollRects(size: bounds.size).distance(at: point) / velocity
        var offset = contentOffset
        offset.y += distance

        let topOffset = -contentInset.top
        let bottomOffset = contentInset.bottom
        let height = floor(contentSize.height) - bounds.size.height

        if offset.y > height + bottomOffset {
            offset.y = height + bottomOffset
        } else if offset.y < topOffset {
            offset.y = topOffset
        }

        return offset
    }

    func draggingDirection(at point: @autoclosure () -> CGPoint) -> DraggingDirection? {
        let contentHeight = floor(contentSize.height)
        if bounds.size.height >= contentHeight {
            return nil
        }

        let rects = ScrollRects(size: bounds.size)
        let point = point()

        if rects.topRect.contains(point) {
            let topOffset = -contentInset.top
            if contentOffset.y > topOffset {
                return .up
            }
        } else if rects.bottomRect.contains(point) {
            let bottomOffset = contentHeight + contentInset.bottom - bounds.size.height
            if contentOffset.y < bottomOffset {
                return .down
            }
        }

        return nil
    }
}
