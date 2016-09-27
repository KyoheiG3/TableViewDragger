//
//  UIScrollViewExtension.swift
//  Pods
//
//  Created by Kyohei Ito on 2015/09/29.
//
//

import UIKit

extension UIScrollView {
    struct ScrollRect {
        fileprivate let maxScrollDistance: CGFloat = 10
        
        fileprivate let rect: CGRect
        let top: CGRect
        let bottom: CGRect
        let scrollRange: CGFloat
        
        init(inRect: CGRect) {
            rect = inRect
            scrollRange = inRect.size.height / 2.5
            
            let size = CGSize(width: inRect.width, height: scrollRange + inRect.origin.y)
            top = CGRect(origin: CGPoint(x: inRect.origin.x, y: -inRect.origin.y), size: size)
            bottom = CGRect(origin: CGPoint(x: inRect.origin.x, y: inRect.size.height - scrollRange), size: size)
        }
        
        func scrollDistance(_ point: CGPoint) -> CGFloat {
            let ratio: CGFloat
            if top.contains(point) {
                ratio = -(scrollRange - point.y)
            } else if bottom.contains(point) {
                ratio = point.y - (rect.height - scrollRange)
            } else {
                ratio = 0
            }
            
            return max(min(ratio / 30, maxScrollDistance), -maxScrollDistance)
        }
    }
    
    func adjustContentOffset(_ distance: CGFloat) -> CGPoint {
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
    
    func autoScrollMotion(_ point: @autoclosure () -> CGPoint) -> DragMotion? {
        let contentHeight = floor(contentSize.height)
        if bounds.size.height >= contentHeight {
            return nil
        }
        
        let scrollRect = ScrollRect(inRect: bounds)
        let point = point()
        
        if scrollRect.top.contains(point) {
            let topOffset = -contentInset.top
            if contentOffset.y > topOffset {
                return .up
            }
        } else if scrollRect.bottom.contains(point) {
            let bottomOffset = contentHeight + contentInset.bottom - bounds.size.height
            if contentOffset.y < bottomOffset {
                return .down
            }
        }
        
        return nil
    }
}
