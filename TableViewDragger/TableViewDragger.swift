//
//  TableViewDragger.swift
//  TableViewDragger
//
//  Created by Kyohei Ito on 2015/09/24.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit

@objc protocol TableViewDraggerDelegate: class {
    func dragger(dragger: TableViewDragger, moveDraggingAtIndexPath fromPath: NSIndexPath, toIndexPath: NSIndexPath) -> Bool
    
    optional func dragger(dragger: TableViewDragger, shouldDragAtIndexPath indexPath: NSIndexPath) -> Bool
    optional func dragger(dragger: TableViewDragger, willBeginDraggingAtIndexPath indexPath: NSIndexPath)
    optional func dragger(dragger: TableViewDragger, didBeginDraggingAtIndexPath indexPath: NSIndexPath)
    optional func dragger(dragger: TableViewDragger, willEndDraggingAtIndexPath indexPath: NSIndexPath)
    optional func dragger(dragger: TableViewDragger, didEndDraggingAtIndexPath indexPath: NSIndexPath)
}

protocol TableViewDraggerDataSource: class {
    func dragger(dragger: TableViewDragger, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell?
    func dragger(dragger: TableViewDragger, cellCoverAtRect rect: CGRect) -> UIView?
    func dragger(dragger: TableViewDragger, removeCoverView view: UIView)
    func dragger(dragger: TableViewDragger, indexPathForDragAtIndexPath indexPath: NSIndexPath) -> NSIndexPath
}

class TableViewDragger: NSObject {
    enum VerticalMotion {
        case Up
        case Down
    }
    
    struct ScrollRect {
        private static let MaxScrollDistance: CGFloat = 10
        
        var top: CGRect
        var bottom: CGRect
        
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
            var ratio: CGFloat = 0
            
            let scrollRange = autoScrollRange(inRect)
            let scrollRect = autoScrollRect(inRect)
            
            if CGRectContainsPoint(scrollRect.top, point) {
                ratio = -(scrollRange - point.y)
            } else if CGRectContainsPoint(scrollRect.bottom, point) {
                ratio = point.y - (inRect.height - scrollRange)
            }
            
            var distance = ratio / 30
            distance = min(distance, MaxScrollDistance)
            distance = max(distance, -MaxScrollDistance)
            return distance
        }
    }
    
    let longPressGesture = UILongPressGestureRecognizer()
    let panGesture = UIPanGestureRecognizer()
    weak var delegate: TableViewDraggerDelegate?
    weak var dataSoutce: TableViewDraggerDataSource?
    weak var tableView: UITableView?
    private var draggingCell: TableViewDraggerCell?
    private var draggingVerticalMotion: VerticalMotion?
    private var coverView: UIView?
    private var displayLink: CADisplayLink?
    private var targetClipsToBounds = true
    
    var originCellHidden: Bool = true
    var cellZoomScale: CGFloat = 1
    var cellAlpha: CGFloat = 1
    var cellShadowOpacity: Float = 0.4
    var scrollVelocity: CGFloat = 1
    
    init(tableView: UITableView) {
        super.init()
        
        self.tableView = tableView
        tableView.addGestureRecognizer(longPressGesture)
        tableView.addGestureRecognizer(panGesture)
        
        longPressGesture.addTarget(self, action: Selector("longPressGestureAction"))
        longPressGesture.delegate = self
        longPressGesture.allowableMovement = 5.0
        
        panGesture.addTarget(self, action: "panGestureAction:")
        panGesture.delegate = self
        panGesture.maximumNumberOfTouches = 1
    }
    
    deinit {
        tableView?.removeGestureRecognizer(longPressGesture)
        tableView?.removeGestureRecognizer(panGesture)
    }
    
    private func autoScrollMotion(point: CGPoint, inScrollView view: UIScrollView) -> VerticalMotion? {
        let contentHeight = floor(view.contentSize.height)
        if view.bounds.size.height >= contentHeight {
            return nil
        }
        
        let scrollRect = ScrollRect.autoScrollRect(view.bounds)
        
        if CGRectContainsPoint(scrollRect.top, point) {
            let topOffset = -view.contentInset.top
            if view.contentOffset.y > topOffset {
                return .Up
            }
        } else if CGRectContainsPoint(scrollRect.bottom, point) {
            let bottomOffset = contentHeight + view.contentInset.bottom - view.bounds.size.height
            if view.contentOffset.y < bottomOffset {
                return .Down
            }
        }
        
        return nil
    }
    
    private func adjustContentOffset(distance: CGFloat, inScrollView view: UIScrollView) -> CGPoint {
        var offset: CGPoint = view.contentOffset
        offset.y += distance
        
        let topOffset = -view.contentInset.top
        let bottomOffset = view.contentInset.bottom
        let height = floor(view.contentSize.height) - view.bounds.size.height
        
        if offset.y > height + bottomOffset {
            offset.y = height + bottomOffset
        } else if offset.y < topOffset {
            offset.y = topOffset
        }
        
        return offset
    }
    
    private func targetIndexPath(tableView: UITableView, draggingCell: TableViewDraggerCell) -> NSIndexPath {
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
    
    private func dragCell(tableView: UITableView, draggingCell: TableViewDraggerCell) {
        let indexPath = targetIndexPath(tableView, draggingCell: draggingCell)
        if draggingCell.dropIndexPath.compare(indexPath) == .OrderedSame {
            return
        }
        
        if let cell = tableView.cellForRowAtIndexPath(draggingCell.dropIndexPath) {
            coverForCell(cell)
        }
        
        if delegate?.dragger(self, moveDraggingAtIndexPath: draggingCell.dropIndexPath, toIndexPath: indexPath) == true {
            draggingCell.dropIndexPath = indexPath
        }
    }
    
    private func coverForCell(cell: UITableViewCell) {
        cell.hidden = originCellHidden
        
        if coverView == nil {
            coverView = dataSoutce?.dragger(self, cellCoverAtRect: cell.contentView.frame)
        }
        if let view = coverView {
            cell.addSubview(view)
        }
    }
    
    private func copiedCellAtIndexPath(indexPath: NSIndexPath, retryCount: Int) -> UITableViewCell? {
        var copiedCell: UITableViewCell? = dataSoutce?.dragger(self, cellForRowAtIndexPath: indexPath)
        if copiedCell == nil {
            if let table = tableView {
                copiedCell = table.dataSource?.tableView(table, cellForRowAtIndexPath: indexPath)
            }
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
    
    private func draggedCell(tableView: UITableView, indexPath: NSIndexPath) -> TableViewDraggerCell? {
        let cellRect = tableView.rectForRowAtIndexPath(indexPath)
        let copiedCell: UITableViewCell! = copiedCellAtIndexPath(indexPath, retryCount: 0)
        if copiedCell == nil {
            return nil
        }
        
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
        displayLink = UIScreen.mainScreen().displayLinkWithTarget(self, selector: "displayDidRefresh:")
        displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        displayLink?.paused = true
        
        var dragIndexPath = indexPath
        if let dataSource = dataSoutce {
            let path = dataSource.dragger(self, indexPathForDragAtIndexPath: indexPath)
            dragIndexPath = path
        }
        
        delegate?.dragger?(self, willBeginDraggingAtIndexPath: dragIndexPath)
        
        if let table = tableView {
            let actualCell = table.cellForRowAtIndexPath(dragIndexPath)
            let point = gesture.locationInView(actualCell)
            if let cell = actualCell {
                coverForCell(cell)
            }
            
            if let draggedCell = draggedCell(table, indexPath: dragIndexPath) {
                draggedCell.offset = point
                draggedCell.transformToPoint(point)
                draggedCell.location = gesture.locationInView(table)
                table.addSubview(draggedCell)
                
                draggingCell = draggedCell
            }
            
            targetClipsToBounds = table.clipsToBounds
            table.clipsToBounds = false
        }
        
        delegate?.dragger?(self, didBeginDraggingAtIndexPath: indexPath)
    }
    
    func draggingChanged(gesture: UIGestureRecognizer, vertical: VerticalMotion?) {
        if let tableView = tableView {
            if let draggingCell = draggingCell {
                draggingCell.location = gesture.locationInView(tableView)
                
                let center = draggingCell.absoluteCenterForScrollView(tableView)
                if let motion = autoScrollMotion(center, inScrollView: tableView) {
                    displayLink?.paused = false
                    draggingVerticalMotion = motion
                } else {
                    draggingVerticalMotion = vertical
                }
                
                dragCell(tableView, draggingCell: draggingCell)
            }
        }
    }
    
    func draggingEnded(gesture: UIGestureRecognizer) {
        displayLink?.invalidate()
        
        if let tableView = tableView {
            if let draggingCell = draggingCell {
                delegate?.dragger?(self, willEndDraggingAtIndexPath: draggingCell.dropIndexPath)
                
                if let view = coverView {
                    dataSoutce?.dragger(self, removeCoverView: view)
                }
                
                let targetRect = tableView.rectForRowAtIndexPath(draggingCell.dropIndexPath)
                let center = CGPoint(x: targetRect.width / 2, y: targetRect.origin.y + (targetRect.height / 2))
                
                draggingCell.drop(center) {
                    self.delegate?.dragger?(self, didEndDraggingAtIndexPath: draggingCell.dropIndexPath)
                    
                    if let cell = tableView.cellForRowAtIndexPath(draggingCell.dropIndexPath) {
                        cell.hidden = false
                    }
                    
                    tableView.clipsToBounds = self.targetClipsToBounds
                    
                    self.coverView?.removeFromSuperview()
                    self.coverView = nil
                    self.draggingCell = nil
                }
            }
        }
    }
}

// MARK: - Action Methods
extension TableViewDragger {
    func displayDidRefresh(displayLink: CADisplayLink) {
        if let tableView = tableView {
            if let draggingCell = draggingCell {
                let center = draggingCell.absoluteCenterForScrollView(tableView)
                
                if let motion = autoScrollMotion(center, inScrollView: tableView) {
                    draggingVerticalMotion = motion
                } else {
                    displayLink.paused = true
                }
                
                let distance = ScrollRect.autoScrollDistance(center, inRect: tableView.bounds) / scrollVelocity
                tableView.contentOffset = adjustContentOffset(distance, inScrollView: tableView)
                
                dragCell(tableView, draggingCell: draggingCell)
                
                draggingCell.location = panGesture.locationInView(tableView)
            }
        }
    }
    
    func longPressGestureAction(gesture: UILongPressGestureRecognizer) {
        let point = gesture.locationInView(tableView)
        
        switch gesture.state {
        case .Began:
            tableView?.scrollEnabled = false
            
            if let path = tableView?.indexPathForRowAtPoint(point) {
                draggingBegin(gesture, indexPath: path)
            }
        case .Ended, .Cancelled:
            draggingEnded(gesture)
            
            tableView?.scrollEnabled = true
            
        case .Changed, .Failed, .Possible:
            break
        }
    }
    
    func panGestureAction(gesture: UIPanGestureRecognizer) {
        if tableView?.scrollEnabled == false && gesture.state == .Changed {
            
            let offsetY = gesture.translationInView(tableView!).y
            if offsetY < 0 {
                draggingChanged(gesture, vertical: .Up)
            } else if offsetY > 0 {
                draggingChanged(gesture, vertical: .Down)
            } else {
                draggingChanged(gesture, vertical: nil)
            }
            
            gesture.setTranslation(CGPointZero, inView: tableView!)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate Methods
extension TableViewDragger: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer == longPressGesture {
            let point = touch.locationInView(tableView)
            
            if let indexPath = tableView?.indexPathForRowAtPoint(point) {
                if let ret = delegate?.dragger?(self, shouldDragAtIndexPath: indexPath) {
                    return ret
                }
            } else {
                return false
            }
        }
        
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == panGesture || otherGestureRecognizer == panGesture || gestureRecognizer == longPressGesture || otherGestureRecognizer == longPressGesture
    }
}