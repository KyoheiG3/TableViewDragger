//
//  TableViewDraggerCell.swift
//  TableViewDragger
//
//  Created by Kyohei Ito on 2015/09/24.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit

class TableViewDraggerCell: UIScrollView {
    private let zoomingView: UIView!

    var dragAlpha: CGFloat = 1
    var dragScale: CGFloat = 1
    var dragShadowOpacity: Float = 0.4

    var dropIndexPath: IndexPath = IndexPath(index: 0)
    var offset: CGPoint = CGPoint.zero {
        didSet {
            offset.x -= (bounds.width / 2)
            offset.y -= (bounds.height / 2)
            center = adjustCenter(location)
        }
    }
    var location: CGPoint = CGPoint.zero {
        didSet {
            center = adjustCenter(location)
        }
    }
    var viewHeight: CGFloat {
        return zoomingView.bounds.height * zoomScale
    }

    private func adjustCenter(_ center: CGPoint) -> CGPoint {
        var center = center
        center.x -= offset.x
        center.y -= offset.y
        return center
    }

    required init?(coder aDecoder: NSCoder) {
        zoomingView = UIView(frame: .zero)
        super.init(coder: aDecoder)
    }

    init(cell: UIView) {
        zoomingView = UIView(frame: cell.bounds)
        zoomingView.addSubview(cell)

        super.init(frame: cell.bounds)

        delegate = self
        clipsToBounds = false

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0
        layer.shadowRadius = 5
        layer.shadowOffset = .zero

        addSubview(zoomingView)
    }

    func transformToPoint(_ point: CGPoint) {
        if dragScale > 1 {
            maximumZoomScale = dragScale
        } else {
            minimumZoomScale = dragScale
        }

        var center = zoomingView.center
        center.x -= (center.x * dragScale) - point.x
        center.y -= (center.y * dragScale) - point.y

        UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseInOut, animations: {
            self.zoomingView.center = center
            self.zoomScale = self.dragScale
            self.alpha = self.dragAlpha
        }, completion: nil)

        CATransaction.begin()
        let anim = CABasicAnimation(keyPath: "shadowOpacity")
        anim.fromValue = 0
        anim.toValue = dragShadowOpacity
        anim.duration = 0.1
        anim.isRemovedOnCompletion = false
        anim.fillMode = .forwards
        layer.add(anim, forKey: "cellDragAnimation")
        CATransaction.commit()
    }

    func adjustedCenter(on scrollView: UIScrollView) -> CGPoint {
        var center = location
        center.y -= scrollView.contentOffset.y
        center.x = scrollView.center.x
        return center
    }

    func drop(_ center: CGPoint, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25) {
            self.zoomingView.adjustCenterAtRect(self.zoomingView.frame)
            self.center = center
            self.zoomScale = 1.0
            self.alpha = 1.0
        }

        CATransaction.begin()
        let anim = CABasicAnimation(keyPath: "shadowOpacity")
        anim.fromValue = dragShadowOpacity
        anim.toValue = 0
        anim.duration = 0.15
        anim.beginTime = CACurrentMediaTime() + 0.15
        anim.isRemovedOnCompletion = false
        anim.fillMode = .forwards
        CATransaction.setCompletionBlock {
            self.removeFromSuperview()

            completion?()
        }
        layer.add(anim, forKey: "cellDropAnimation")
        CATransaction.commit()
    }
}

extension TableViewDraggerCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomingView
    }
}

private extension UIView {
    func adjustCenterAtRect(_ rect: CGRect) {
        let center = CGPoint(x: rect.size.width / 2, y: rect.size.height / 2)
        self.center = center
    }
}
