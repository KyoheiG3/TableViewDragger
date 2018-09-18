# TableViewDragger

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/TableViewDragger.svg?style=flat)](http://cocoadocs.org/docsets/TableViewDragger)
[![License](https://img.shields.io/cocoapods/l/TableViewDragger.svg?style=flat)](http://cocoadocs.org/docsets/TableViewDragger)
[![Platform](https://img.shields.io/cocoapods/p/TableViewDragger.svg?style=flat)](http://cocoadocs.org/docsets/TableViewDragger)

![simple](https://user-images.githubusercontent.com/5707132/33757706-a5b5cf6c-dc3e-11e7-9275-b54b7897da59.gif)![image](https://user-images.githubusercontent.com/5707132/33757803-19c44622-dc3f-11e7-913e-b39aa3f45791.gif)

This is a demo that uses a `TableViewDragger`.

#### [Appetize's Demo](https://appetize.io/app/p92e7wrmfkq32t473fuavn8bmm)

## Requirements

- Swift 4.2
- iOS 8.0 or later

## How to Install TableViewDragger

#### CocoaPods

Add the following to your `Podfile`:

```Ruby
pod "TableViewDragger"
```

#### Carthage

Add the following to your `Cartfile`:

```Ruby
github "KyoheiG3/TableViewDragger"
```

## Usage

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
var isHiddenOriginCell: Bool
```
* It will be `true` if want to hide the original cell.
* Default is `true`.

```swift
var zoomScaleForCell: CGFloat
```
* Zoom scale of cell in drag.
* Default is `1`.

```swift
var alphaForCell: CGFloat
```
* Alpha of cell in drag.
* Default is `1`.

```swift
var opacityForShadowOfCell: Float
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
optional func dragger(_ dragger: TableViewDragger, cellForRowAt indexPath: IndexPath) -> UIView?
```
* Return any cell if want to change the cell in drag.

```swift
optional func dragger(_ dragger: TableViewDragger, indexPathForDragAt indexPath: IndexPath) -> IndexPath
```
* Return the indexPath if want to change the indexPath to start drag.

### TableViewDraggerDelegate Function

```swift
func dragger(_ dragger: TableViewDragger, moveDraggingAt indexPath: IndexPath, newIndexPath: IndexPath) -> Bool
```
* If allow movement of cell, please return `true`. require a call to `moveRowAtIndexPath:toIndexPath:` of UITableView and rearranged of data.

```swift
optional func dragger(_ dragger: TableViewDragger, shouldDragAt indexPath: IndexPath) -> Bool
```
* If allow dragging of cell, prease return `true`.

## Author

#### Kyohei Ito

- [GitHub](https://github.com/kyoheig3)
- [Twitter](https://twitter.com/kyoheig3)

Follow me 🎉

## LICENSE

Under the MIT license. See LICENSE file for details.
