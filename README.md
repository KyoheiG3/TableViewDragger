# TableViewDragger

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/TableViewDragger.svg?style=flat)](http://cocoadocs.org/docsets/TableViewDragger)
[![License](https://img.shields.io/cocoapods/l/TableViewDragger.svg?style=flat)](http://cocoadocs.org/docsets/TableViewDragger)
[![Platform](https://img.shields.io/cocoapods/p/TableViewDragger.svg?style=flat)](http://cocoadocs.org/docsets/TableViewDragger)

![Demo](https://github.com/KyoheiG3/assets/blob/master/TableViewDragger/dragger.gif)

This is a demo that uses a `TableViewDragger`.  

#### [Appetize's Demo](https://appetize.io/app/p92e7wrmfkq32t473fuavn8bmm)

## Requirements

- Swift 3.0
- iOS 7.0 or later

## How to Install TableViewDragger

### iOS 8+

#### CocoaPods

Add the following to your `Podfile`:

```Ruby
use_frameworks!
pod "TableViewDragger"
```
Note: the `use_frameworks!` is required for pods made in Swift.

#### Carthage

Add the following to your `Cartfile`:

```Ruby
github "KyoheiG3/TableViewDragger"
```

### iOS 7

Just add everything in the `TableViewDragger.swift` and `TableViewDraggerCell.swift` file to your project.

## Usage

### import

If target is ios8.0 or later, please import the `TableViewDragger`.

```swift
import TableViewDragger
```

### TableViewDragger Variable

```swift
weak var delegate: TableViewDraggerDelegate?
```
* Delegate of `TableViewDragger`.

```swift
weak var dataSource: TableViewDraggerDataSource?
```
* DataSource of `TableViewDragger`.

```swift
var originCellHidden: Bool
```
* It will be `true` if want to hide the original cell.
* Default is `true`.

```swift
var cellZoomScale: CGFloat
```
* Zoom scale of cell in drag.
* Default is `1`.

```swift
var cellAlpha: CGFloat
```
* Alpha of cell in drag.
* Default is `1`.

```swift
var cellShadowOpacity: Float
```
* Opacity of cell shadow in drag.
* Default is `0.4`.

```swift
var scrollVelocity: CGFloat
```
* Velocity of auto scroll in drag.
* Default is `1`.

### TableViewDragger Function

```swift
init(tableView: UITableView)
```
* `UITableView` want to drag.

### TableViewDraggerDataSource Function

```swift
optional func dragger(dragger: TableViewDragger.TableViewDragger, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell?
```
* Return any cell if want to change the cell in drag.

```swift
optional func dragger(dragger: TableViewDragger.TableViewDragger, indexPathForDragAtIndexPath indexPath: NSIndexPath) -> NSIndexPath
```
* Return the indexPath if want to change the indexPath to start drag.

### TableViewDraggerDelegate Function

```swift
func dragger(dragger: TableViewDragger.TableViewDragger, moveDraggingAtIndexPath indexPath: NSIndexPath, newIndexPath: NSIndexPath) -> Bool
```
* If allow movement of cell, please return `true`. require a call to `moveRowAtIndexPath:toIndexPath:` of UITableView and rearranged of data.

```swift
optional func dragger(dragger: TableViewDragger.TableViewDragger, shouldDragAtIndexPath indexPath: NSIndexPath) -> Bool
```
* If allow dragging of cell, prease return `true`.

## LICENSE

Under the MIT license. See LICENSE file for details.
