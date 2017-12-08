//
//  ScrollRects.swift
//  TableViewDragger
//
//  Created by Kyohei Ito on 2017/12/08.
//  Copyright © 2017年 kyohei_ito. All rights reserved.
//

import Foundation

struct ScrollRects {
    private let maxDistance: CGFloat = 10
    private let size: CGSize
    private let scrollRange: CGFloat

    let topRect: CGRect
    let bottomRect: CGRect

    init(size: CGSize) {
        self.size = size
        scrollRange = size.height / 2.5

        let scrollSize = CGSize(width: size.width, height: scrollRange)
        topRect = CGRect(origin: .zero, size: scrollSize)
        bottomRect = CGRect(origin: CGPoint(x: 0, y: size.height - scrollRange), size: scrollSize)
    }

    func distance(at point: CGPoint) -> CGFloat {
        let ratio: CGFloat
        if topRect.contains(point) {
            ratio = -(scrollRange - point.y)
        } else if bottomRect.contains(point) {
            ratio = point.y - (size.height - scrollRange)
        } else {
            ratio = 0
        }

        return max(min(ratio / 30, maxDistance), -maxDistance)
    }
}
