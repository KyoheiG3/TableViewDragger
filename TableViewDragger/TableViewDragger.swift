//
//  TableViewDragger.swift
//  TableViewDragger
//
//  Created by Kyohei Ito on 2015/09/24.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit

@objc public protocol TableViewDraggerDelegate: class {
    /// If allow movement of cell, please return `true`. require a call to `moveRowAtIndexPath:toIndexPath:` of UITableView and rearranged of data.
    func dragger(dragger: TableViewDragger, moveDraggingAtIndexPath indexPath: NSIndexPath, newIndexPath: NSIndexPath) -> Bool
    
    /// If allow dragging of cell, prease return `true`.
    optional func dragger(dragger: TableViewDragger, shouldDragAtIndexPath indexPath: NSIndexPath) -> Bool
    optional func dragger(dragger: TableViewDragger, willBeginDraggingAtIndexPath indexPath: NSIndexPath)
    optional func dragger(dragger: TableViewDragger, didBeginDraggingAtIndexPath indexPath: NSIndexPath)
    optional func dragger(dragger: TableViewDragger, willEndDraggingAtIndexPath indexPath: NSIndexPath)
    optional func dragger(dragger: TableViewDragger, didEndDraggingAtIndexPath indexPath: NSIndexPath)
}

@objc public protocol TableViewDraggerDataSource: class {
    /// Return any cell if want to change the cell in drag.
    optional func dragger(dragger: TableViewDragger, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell?
    /// Return the indexPath if want to change the indexPath to start drag.
    optional func dragger(dragger: TableViewDragger, indexPathForDragAtIndexPath indexPath: NSIndexPath) -> NSIndexPath
}

public class TableViewDragger: NSObject {
    let longPressGesture = UILongPressGestureRecognizer()
    let panGesture = UIPanGestureRecognizer()
    var draggingCell: TableViewDraggerCell?
    var displayLink: CADisplayLink?
    var targetClipsToBounds = true
    weak var targetTableView: UITableView?
    private var draggingVerticalMotion: UIScrollView.DragMotion?
    
    /// It will be `true` if want to hide the original cell.
    public var originCellHidden: Bool = true
    /// Zoom scale of cell in drag.
    public var cellZoomScale: CGFloat = 1
    /// Alpha of cell in drag.
    public var cellAlpha: CGFloat = 1
    /// Opacity of cell shadow in drag.
    public var cellShadowOpacity: Float = 0.4
    /// Velocity of auto scroll in drag.
    public var scrollVelocity: CGFloat = 1
    public weak var delegate: TableViewDraggerDelegate?
    public weak var dataSource: TableViewDraggerDataSource?
    public var tableView: UITableView? {
        return targetTableView
    }
    
    /// `UITableView` want to drag.
    public init(tableView: UITableView) {
        super.init()
        
        self.targetTableView = tableView
        tableView.addGestureRecognizer(longPressGesture)
        tableView.addGestureRecognizer(panGesture)
        
        longPressGesture.addTarget(self, action: Selector("longPressGestureAction:"))
        longPressGesture.delegate = self
        longPressGesture.allowableMovement = 5.0
        
        panGesture.addTarget(self, action: Selector("panGestureAction:"))
        panGesture.delegate = self
        panGesture.maximumNumberOfTouches = 1
    }
    
    deinit {
        targetTableView?.removeGestureRecognizer(longPressGesture)
        targetTableView?.removeGestureRecognizer(panGesture)
    }
    
    func targetIndexPath(tableView: UITableView, draggingCell: TableViewDraggerCell) -> NSIndexPath {
        let location        = draggingCell.location
        let offsetY         = (draggingCell.viewHeight / 2) + 2
        let offsetX         = tableView.center.x
        let topPoint        = CGPoint(x: offsetX, y: location.y - offsetY)
        let bottomPoint     = CGPoint(x: offsetX, y: location.y + offsetY)
        let point           = draggingVerticalMotion == .Up ? topPoint : bottomPoint
        
        if let targetIndexPath = tableView.indexPathForRowAtPoint(point) {
            let cell = tableView.cellForRowAtIndexPath(targetIndexPath)
            if cell == nil {
                return draggingCell.dropIndexPath
            }
            
            let targetRect = tableView.rectForRowAtIndexPath(targetIndexPath)
            let targetCenterY = targetRect.origin.y + (targetRect.height / 2)
            
            switch draggingVerticalMotion {
            case .Some(.Up):
                if (targetCenterY > point.y && draggingCell.dropIndexPath.compare(targetIndexPath) == .OrderedDescending) {
                    return targetIndexPath
                }
            case .Some(.Down):
                if (targetCenterY < point.y && draggingCell.dropIndexPath.compare(targetIndexPath) == .OrderedAscending) {
                    return targetIndexPath
                }
            default:
                break;
            }
        }
        
        return draggingCell.dropIndexPath
    }
    
    func dragCell(tableView: UITableView, draggingCell: TableViewDraggerCell) {
        let indexPath = targetIndexPath(tableView, draggingCell: draggingCell)
        if draggingCell.dropIndexPath.compare(indexPath) == .OrderedSame {
            return
        }
        
        if let cell = tableView.cellForRowAtIndexPath(draggingCell.dropIndexPath) {
            cell.hidden = originCellHidden
        }
        if delegate?.dragger(self, moveDraggingAtIndexPath: draggingCell.dropIndexPath, newIndexPath: indexPath) == true {
            draggingCell.dropIndexPath = indexPath
        }
    }
    
    func copiedCellAtIndexPath(indexPath: NSIndexPath, retryCount: Int) -> UITableViewCell? {
        var copiedCell = dataSource?.dragger?(self, cellForRowAtIndexPath: indexPath)
        if copiedCell == nil, let tableView = targetTableView {
            copiedCell = tableView.dataSource?.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
        
        if copiedCell?.hidden == true {
            if retryCount > 10 {
                return nil
            }
            // retry
            return copiedCellAtIndexPath(indexPath, retryCount: retryCount + 1)
        }
        
        return copiedCell
    }
    
    func draggedCell(tableView: UITableView, indexPath: NSIndexPath) -> TableViewDraggerCell? {
        guard let copiedCell = copiedCellAtIndexPath(indexPath, retryCount: 0) else {
            return nil
        }
        
        let cellRect = tableView.rectForRowAtIndexPath(indexPath)
        copiedCell.bounds.size = cellRect.size
        
        if let height = tableView.delegate?.tableView?(tableView, heightForRowAtIndexPath: indexPath) {
            copiedCell.bounds.size.height = height
        }
        
        let cell = TableViewDraggerCell(cell: copiedCell)
        cell.dragScale = cellZoomScale
        cell.dragAlpha = cellAlpha
        cell.dragShadowOpacity = cellShadowOpacity
        cell.dropIndexPath = indexPath
        
        return cell
    }
    
    func draggingBegin(gesture: UIGestureRecognizer, indexPath: NSIndexPath) {
        displayLink?.invalidate()
        displayLink = UIScreen.mainScreen().displayLinkWithTarget(self, selector: Selector("displayDidRefresh:"))
        displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        displayLink?.paused = true
        
        let dragIndexPath = dataSource?.dragger?(self, indexPathForDragAtIndexPath: indexPath) ?? indexPath
        delegate?.dragger?(self, willBeginDraggingAtIndexPath: dragIndexPath)
        
        if let tableView = targetTableView {
            let actualCell = tableView.cellForRowAtIndexPath(dragIndexPath)
            actualCell?.hidden = originCellHidden
            
            if let draggedCell = draggedCell(tableView, indexPath: dragIndexPath) {
                let point = gesture.locationInView(actualCell)
                draggedCell.offset = point
                draggedCell.transformToPoint(point)
                draggedCell.location = gesture.locationInView(tableView)
                tableView.addSubview(draggedCell)
                
                draggingCell = draggedCell
            }
            
            targetClipsToBounds = tableView.clipsToBounds
            tableView.clipsToBounds = false
        }
        
        delegate?.dragger?(self, didBeginDraggingAtIndexPath: indexPath)
    }
    
    private func draggingChanged(gesture: UIGestureRecognizer, vertical: UIScrollView.DragMotion?) {
        if let tableView = targetTableView, draggingCell = draggingCell {
            draggingCell.location = gesture.locationInView(tableView)
            
            let center = draggingCell.absoluteCenterForScrollView(tableView)
            if let motion = tableView.autoScrollMotion(center) {
                displayLink?.paused = false
                draggingVerticalMotion = motion
            } else {
                draggingVerticalMotion = vertical
            }
            
            dragCell(tableView, draggingCell: draggingCell)
        }
    }
    
    func draggingEnded(gesture: UIGestureRecognizer) {
        displayLink?.invalidate()
        
        if let tableView = targetTableView, draggingCell = draggingCell {
            delegate?.dragger?(self, willEndDraggingAtIndexPath: draggingCell.dropIndexPath)
            
            let targetRect = tableView.rectForRowAtIndexPath(draggingCell.dropIndexPath)
            let center = CGPoint(x: targetRect.width / 2, y: targetRect.origin.y + (targetRect.height / 2))
            
            draggingCell.drop(center) {
                self.delegate?.dragger?(self, didEndDraggingAtIndexPath: draggingCell.dropIndexPath)
                
                if let cell = tableView.cellForRowAtIndexPath(draggingCell.dropIndexPath) {
                    cell.hidden = false
                }
                
                tableView.clipsToBounds = self.targetClipsToBounds
                
                self.draggingCell = nil
            }
        }
    }
}

// MARK: - Action Methods
private extension TableViewDragger {
    dynamic func displayDidRefresh(displayLink: CADisplayLink) {
        if let tableView = targetTableView, draggingCell = draggingCell {
            let center = draggingCell.absoluteCenterForScrollView(tableView)
            
            if let motion = tableView.autoScrollMotion(center) {
                draggingVerticalMotion = motion
            } else {
                displayLink.paused = true
            }
            
            let distance = UIScrollView.ScrollRect.autoScrollDistance(center, inRect: tableView.bounds) / scrollVelocity
            tableView.contentOffset = tableView.adjustContentOffset(distance)
            
            dragCell(tableView, draggingCell: draggingCell)
            
            draggingCell.location = panGesture.locationInView(tableView)
        }
    }
    
    dynamic func longPressGestureAction(gesture: UILongPressGestureRecognizer) {
        let point = gesture.locationInView(targetTableView)
        
        switch gesture.state {
        case .Began:
            targetTableView?.scrollEnabled = false
            
            if let path = targetTableView?.indexPathForRowAtPoint(point) {
                draggingBegin(gesture, indexPath: path)
            }
        case .Ended, .Cancelled:
            draggingEnded(gesture)
            
            targetTableView?.scrollEnabled = true
            
        case .Changed, .Failed, .Possible:
            break
        }
    }
    
    dynamic func panGestureAction(gesture: UIPanGestureRecognizer) {
        if targetTableView?.scrollEnabled == false && gesture.state == .Changed {
            
            let offsetY = gesture.translationInView(targetTableView).y
            if offsetY < 0 {
                draggingChanged(gesture, vertical: .Up)
            } else if offsetY > 0 {
                draggingChanged(gesture, vertical: .Down)
            } else {
                draggingChanged(gesture, vertical: nil)
            }
            
            gesture.setTranslation(CGPoint.zero, inView: targetTableView)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate Methods
extension TableViewDragger: UIGestureRecognizerDelegate {
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer == longPressGesture {
            let point = touch.locationInView(targetTableView)
            
            if let indexPath = targetTableView?.indexPathForRowAtPoint(point) {
                if let ret = delegate?.dragger?(self, shouldDragAtIndexPath: indexPath) {
                    return ret
                }
            } else {
                return false
            }
        }
        
        return true
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == panGesture || otherGestureRecognizer == panGesture || gestureRecognizer == longPressGesture || otherGestureRecognizer == longPressGesture
    }
}

private extension UIScrollView {
    enum DragMotion {
        case Up
        case Down
    }
    
    struct ScrollRect {
        private static let MaxScrollDistance: CGFloat = 10
        
        let top: CGRect
        let bottom: CGRect
        
        static func autoScrollRange(inRect: CGRect) -> CGFloat {
            return inRect.size.height / 2.5
        }
        
        static func autoScrollRect(inRect: CGRect) -> ScrollRect {
            let scrollRange = autoScrollRange(inRect)
            
            var topRect = inRect
            topRect.origin.y = -inRect.origin.y
            topRect.size.height = scrollRange + inRect.origin.y
            
            var bottomRect = inRect
            bottomRect.origin.y = inRect.size.height - scrollRange
            bottomRect.size.height = scrollRange + inRect.origin.y
            return ScrollRect(top: topRect, bottom: bottomRect)
        }
        
        static func autoScrollDistance(point: CGPoint, inRect: CGRect) -> CGFloat {
            let ratio: CGFloat
            let scrollRange = autoScrollRange(inRect)
            let scrollRect = autoScrollRect(inRect)
            
            if CGRectContainsPoint(scrollRect.top, point) {
                ratio = -(scrollRange - point.y)
            } else if CGRectContainsPoint(scrollRect.bottom, point) {
                ratio = point.y - (inRect.height - scrollRange)
            } else {
                ratio = 0
            }
            
            return max(min(ratio / 30, MaxScrollDistance), -MaxScrollDistance)
        }
    }
    
    func adjustContentOffset(distance: CGFloat) -> CGPoint {
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
    
    func autoScrollMotion(point: CGPoint) -> DragMotion? {
        let contentHeight = floor(contentSize.height)
        if bounds.size.height >= contentHeight {
            return nil
        }
        
        let scrollRect = ScrollRect.autoScrollRect(bounds)
        
        if CGRectContainsPoint(scrollRect.top, point) {
            let topOffset = -contentInset.top
            if contentOffset.y > topOffset {
                return .Up
            }
        } else if CGRectContainsPoint(scrollRect.bottom, point) {
            let bottomOffset = contentHeight + contentInset.bottom - bounds.size.height
            if contentOffset.y < bottomOffset {
                return .Down
            }
        }
        
        return nil
    }
}
