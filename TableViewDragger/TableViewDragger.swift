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
    func dragger(_ dragger: TableViewDragger, moveDraggingAtIndexPath indexPath: IndexPath, newIndexPath: IndexPath) -> Bool
    
    /// If allow dragging of cell, prease return `true`.
    @objc optional func dragger(_ dragger: TableViewDragger, shouldDragAtIndexPath indexPath: IndexPath) -> Bool
    @objc optional func dragger(_ dragger: TableViewDragger, willBeginDraggingAtIndexPath indexPath: IndexPath)
    @objc optional func dragger(_ dragger: TableViewDragger, didBeginDraggingAtIndexPath indexPath: IndexPath)
    @objc optional func dragger(_ dragger: TableViewDragger, willEndDraggingAtIndexPath indexPath: IndexPath)
    @objc optional func dragger(_ dragger: TableViewDragger, didEndDraggingAtIndexPath indexPath: IndexPath)
}

@objc public protocol TableViewDraggerDataSource: class {
    /// Return any cell if want to change the cell in drag.
    @objc optional func dragger(_ dragger: TableViewDragger, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell?
    /// Return the indexPath if want to change the indexPath to start drag.
    @objc optional func dragger(_ dragger: TableViewDragger, indexPathForDragAtIndexPath indexPath: IndexPath) -> IndexPath
}

open class TableViewDragger: NSObject {
    let longPressGesture = UILongPressGestureRecognizer()
    let panGesture = UIPanGestureRecognizer()
    var draggingCell: TableViewDraggerCell?
    var displayLink: CADisplayLink?
    var targetClipsToBounds = true
    weak var targetTableView: UITableView?
    fileprivate var draggingVerticalMotion: UIScrollView.DragMotion?
    
    /// It will be `true` if want to hide the original cell.
    open var originCellHidden: Bool = true
    /// Zoom scale of cell in drag.
    open var cellZoomScale: CGFloat = 1
    /// Alpha of cell in drag.
    open var cellAlpha: CGFloat = 1
    /// Opacity of cell shadow in drag.
    open var cellShadowOpacity: Float = 0.4
    /// Velocity of auto scroll in drag.
    open var scrollVelocity: CGFloat = 1
    open weak var delegate: TableViewDraggerDelegate?
    open weak var dataSource: TableViewDraggerDataSource?
    open var tableView: UITableView? {
        return targetTableView
    }
    
    /// `UITableView` want to drag.
    public init(tableView: UITableView) {
        super.init()
        
        self.targetTableView = tableView
        tableView.addGestureRecognizer(longPressGesture)
        tableView.addGestureRecognizer(panGesture)
        
        longPressGesture.addTarget(self, action: #selector(TableViewDragger.longPressGestureAction(_:)))
        longPressGesture.delegate = self
        longPressGesture.allowableMovement = 5.0
        
        panGesture.addTarget(self, action: #selector(TableViewDragger.panGestureAction(_:)))
        panGesture.delegate = self
        panGesture.maximumNumberOfTouches = 1
    }
    
    deinit {
        targetTableView?.removeGestureRecognizer(longPressGesture)
        targetTableView?.removeGestureRecognizer(panGesture)
    }
    
    func targetIndexPath(_ tableView: UITableView, draggingCell: TableViewDraggerCell) -> IndexPath {
        let location        = draggingCell.location
        let offsetY         = (draggingCell.viewHeight / 2) + 2
        let offsetX         = tableView.center.x
        let topPoint        = CGPoint(x: offsetX, y: location.y - offsetY)
        let bottomPoint     = CGPoint(x: offsetX, y: location.y + offsetY)
        let point           = draggingVerticalMotion == .up ? topPoint : bottomPoint
        
        if let targetIndexPath = tableView.indexPathForRow(at: point) {
            if tableView.cellForRow(at: targetIndexPath) == nil {
                return draggingCell.dropIndexPath as IndexPath
            }
            
            let targetRect = tableView.rectForRow(at: targetIndexPath)
            let targetCenterY = targetRect.origin.y + (targetRect.height / 2)
            
            guard let motion = draggingVerticalMotion else {
                return draggingCell.dropIndexPath as IndexPath
            }
            
            switch motion {
            case .up:
                if (targetCenterY > point.y && (draggingCell.dropIndexPath as NSIndexPath).compare(targetIndexPath) == .orderedDescending) {
                    return targetIndexPath
                }
            case .down:
                if (targetCenterY < point.y && (draggingCell.dropIndexPath as NSIndexPath).compare(targetIndexPath) == .orderedAscending) {
                    return targetIndexPath
                }
            }
        }
        
        return draggingCell.dropIndexPath as IndexPath
    }
    
    func dragCell(_ tableView: UITableView, draggingCell: TableViewDraggerCell) {
        let indexPath = targetIndexPath(tableView, draggingCell: draggingCell)
        if (draggingCell.dropIndexPath as NSIndexPath).compare(indexPath) == .orderedSame {
            return
        }
        
        if let cell = tableView.cellForRow(at: draggingCell.dropIndexPath as IndexPath) {
            cell.isHidden = originCellHidden
        }
        if delegate?.dragger(self, moveDraggingAtIndexPath: draggingCell.dropIndexPath as IndexPath, newIndexPath: indexPath) == true {
            draggingCell.dropIndexPath = indexPath
        }
    }
    
    func copiedCellAtIndexPath(_ indexPath: IndexPath, retryCount: Int) -> UITableViewCell? {
        var copiedCell = dataSource?.dragger?(self, cellForRowAtIndexPath: indexPath)
        if copiedCell == nil, let tableView = targetTableView {
            copiedCell = tableView.dataSource?.tableView(tableView, cellForRowAt: indexPath)
        }
        
        if copiedCell?.isHidden == true {
            if retryCount > 10 {
                return nil
            }
            // retry
            return copiedCellAtIndexPath(indexPath, retryCount: retryCount + 1)
        }
        
        return copiedCell
    }
    
    func draggedCell(_ tableView: UITableView, indexPath: IndexPath) -> TableViewDraggerCell? {
        guard let copiedCell = copiedCellAtIndexPath(indexPath, retryCount: 0) else {
            return nil
        }
        
        let cellRect = tableView.rectForRow(at: indexPath)
        copiedCell.bounds.size = cellRect.size
        
        if let height = tableView.delegate?.tableView?(tableView, heightForRowAt: indexPath) {
            copiedCell.bounds.size.height = height
        }
        
        let cell = TableViewDraggerCell(cell: copiedCell)
        cell.dragScale = cellZoomScale
        cell.dragAlpha = cellAlpha
        cell.dragShadowOpacity = cellShadowOpacity
        cell.dropIndexPath = indexPath
        
        return cell
    }
    
    func draggingBegin(_ gesture: UIGestureRecognizer, indexPath: IndexPath) {
        displayLink?.invalidate()
        displayLink = UIScreen.main.displayLink(withTarget: self, selector: #selector(TableViewDragger.displayDidRefresh(_:)))
        displayLink?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        displayLink?.isPaused = true
        
        let dragIndexPath = dataSource?.dragger?(self, indexPathForDragAtIndexPath: indexPath) ?? indexPath
        delegate?.dragger?(self, willBeginDraggingAtIndexPath: dragIndexPath)
        
        if let tableView = targetTableView {
            let actualCell = tableView.cellForRow(at: dragIndexPath)
            actualCell?.isHidden = originCellHidden
            
            if let draggedCell = draggedCell(tableView, indexPath: dragIndexPath) {
                let point = gesture.location(in: actualCell)
                draggedCell.offset = point
                draggedCell.transformToPoint(point)
                draggedCell.location = gesture.location(in: tableView)
                tableView.addSubview(draggedCell)
                
                draggingCell = draggedCell
            }
            
            targetClipsToBounds = tableView.clipsToBounds
            tableView.clipsToBounds = false
        }
        
        delegate?.dragger?(self, didBeginDraggingAtIndexPath: indexPath)
    }
    
    fileprivate func draggingChanged(_ gesture: UIGestureRecognizer, vertical: UIScrollView.DragMotion?) {
        guard let tableView = targetTableView, let draggingCell = draggingCell else {
            return
        }
        
        draggingCell.location = gesture.location(in: tableView)
        
        if let motion = tableView.autoScrollMotion(draggingCell.absoluteCenterForScrollView(tableView)) {
            displayLink?.isPaused = false
            draggingVerticalMotion = motion
        } else {
            draggingVerticalMotion = vertical
        }
        
        dragCell(tableView, draggingCell: draggingCell)
    }
    
    func draggingEnded(_ gesture: UIGestureRecognizer) {
        displayLink?.invalidate()
        
        guard let tableView = targetTableView, let draggingCell = draggingCell else {
            return
        }
        
        delegate?.dragger?(self, willEndDraggingAtIndexPath: draggingCell.dropIndexPath as IndexPath)
        
        let targetRect = tableView.rectForRow(at: draggingCell.dropIndexPath as IndexPath)
        let center = CGPoint(x: targetRect.width / 2, y: targetRect.origin.y + (targetRect.height / 2))
        
        draggingCell.drop(center) {
            self.delegate?.dragger?(self, didEndDraggingAtIndexPath: draggingCell.dropIndexPath)
            
            if let cell = tableView.cellForRow(at: draggingCell.dropIndexPath) {
                cell.isHidden = false
            }
            
            tableView.clipsToBounds = self.targetClipsToBounds
            
            self.draggingCell = nil
        }
    }
}

// MARK: - Action Methods
private extension TableViewDragger {
    dynamic func displayDidRefresh(_ displayLink: CADisplayLink) {
        guard let tableView = targetTableView, let draggingCell = draggingCell else {
            return
        }
        
        let center = draggingCell.absoluteCenterForScrollView(tableView)
        
        if let motion = tableView.autoScrollMotion(center) {
            draggingVerticalMotion = motion
        } else {
            displayLink.isPaused = true
        }
        
        let distance = UIScrollView.ScrollRect(inRect: tableView.bounds).scrollDistance(center) / scrollVelocity
        tableView.contentOffset = tableView.adjustContentOffset(distance)
        
        dragCell(tableView, draggingCell: draggingCell)
        
        draggingCell.location = panGesture.location(in: tableView)
    }
    
    dynamic func longPressGestureAction(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            targetTableView?.isScrollEnabled = false
            
            let point = gesture.location(in: targetTableView)
            if let path = targetTableView?.indexPathForRow(at: point) {
                draggingBegin(gesture, indexPath: path)
            }
        case .ended, .cancelled:
            draggingEnded(gesture)
            
            targetTableView?.isScrollEnabled = true
            
        case .changed, .failed, .possible:
            break
        }
    }
    
    dynamic func panGestureAction(_ gesture: UIPanGestureRecognizer) {
        if targetTableView?.isScrollEnabled == false && gesture.state == .changed {
            
            let offsetY = gesture.translation(in: targetTableView).y
            if offsetY < 0 {
                draggingChanged(gesture, vertical: .up)
            } else if offsetY > 0 {
                draggingChanged(gesture, vertical: .down)
            } else {
                draggingChanged(gesture, vertical: nil)
            }
            
            gesture.setTranslation(CGPoint.zero, in: targetTableView)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate Methods
extension TableViewDragger: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == longPressGesture {
            let point = touch.location(in: targetTableView)
            
            if let indexPath = targetTableView?.indexPathForRow(at: point) {
                if let ret = delegate?.dragger?(self, shouldDragAtIndexPath: indexPath) {
                    return ret
                }
            } else {
                return false
            }
        }
        
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == panGesture || otherGestureRecognizer == panGesture || gestureRecognizer == longPressGesture || otherGestureRecognizer == longPressGesture
    }
}

extension UIScrollView {
    enum DragMotion {
        case up
        case down
    }
}
