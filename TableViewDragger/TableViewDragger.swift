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
            if tableView.cellForRowAtIndexPath(targetIndexPath) == nil {
                return draggingCell.dropIndexPath
            }
            
            let targetRect = tableView.rectForRowAtIndexPath(targetIndexPath)
            let targetCenterY = targetRect.origin.y + (targetRect.height / 2)
            
            guard let motion = draggingVerticalMotion else {
                return draggingCell.dropIndexPath
            }
            
            switch motion {
            case .Up:
                if (targetCenterY > point.y && draggingCell.dropIndexPath.compare(targetIndexPath) == .OrderedDescending) {
                    return targetIndexPath
                }
            case .Down:
                if (targetCenterY < point.y && draggingCell.dropIndexPath.compare(targetIndexPath) == .OrderedAscending) {
                    return targetIndexPath
                }
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
        guard let tableView = targetTableView, draggingCell = draggingCell else {
            return
        }
        
        draggingCell.location = gesture.locationInView(tableView)
        
        if let motion = tableView.autoScrollMotion(draggingCell.absoluteCenterForScrollView(tableView)) {
            displayLink?.paused = false
            draggingVerticalMotion = motion
        } else {
            draggingVerticalMotion = vertical
        }
        
        dragCell(tableView, draggingCell: draggingCell)
    }
    
    func draggingEnded(gesture: UIGestureRecognizer) {
        displayLink?.invalidate()
        
        guard let tableView = targetTableView, draggingCell = draggingCell else {
            return
        }
        
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

// MARK: - Action Methods
private extension TableViewDragger {
    dynamic func displayDidRefresh(displayLink: CADisplayLink) {
        guard let tableView = targetTableView, draggingCell = draggingCell else {
            return
        }
        
        let center = draggingCell.absoluteCenterForScrollView(tableView)
        
        if let motion = tableView.autoScrollMotion(center) {
            draggingVerticalMotion = motion
        } else {
            displayLink.paused = true
        }
        
        let distance = UIScrollView.ScrollRect(inRect: tableView.bounds).scrollDistance(center) / scrollVelocity
        tableView.contentOffset = tableView.adjustContentOffset(distance)
        
        dragCell(tableView, draggingCell: draggingCell)
        
        draggingCell.location = panGesture.locationInView(tableView)
    }
    
    dynamic func longPressGestureAction(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .Began:
            targetTableView?.scrollEnabled = false
            
            let point = gesture.locationInView(targetTableView)
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

extension UIScrollView {
    enum DragMotion {
        case Up
        case Down
    }
}
