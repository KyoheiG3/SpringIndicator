# SpringIndicator

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/SpringIndicator.svg?style=flat)](http://cocoadocs.org/docsets/SpringIndicator)
[![License](https://img.shields.io/cocoapods/l/SpringIndicator.svg?style=flat)](http://cocoadocs.org/docsets/SpringIndicator)
[![Platform](https://img.shields.io/cocoapods/p/SpringIndicator.svg?style=flat)](http://cocoadocs.org/docsets/SpringIndicator)

#### [Appetize's Demo](https://appetize.io/app/taw1k1486yhxqy35gv7jrver7g)

* Refresher is a simple as UIRefreshControl.
* Don't need to add a UIScrollView delegate.

* Demo gif  
![Indicator](https://github.com/KyoheiG3/assets/blob/master/SpringIndicator/indicator.gif)
![Refresher](https://github.com/KyoheiG3/assets/blob/master/SpringIndicator/refresher.gif)

* Image capture  
![Image](https://github.com/KyoheiG3/assets/blob/master/SpringIndicator/refresher.png)


## How to Install SpringIndicator

### iOS 8+

#### Cocoapods

Add the following to your `Podfile`:

```Ruby
pod "SpringIndicator"
use_frameworks!
```
Note: the `use_frameworks!` is required for pods made in Swift.

#### Carthage

Add the following to your `Cartfile`:

```Ruby
github "KyoheiG3/SpringIndicator"
```

### iOS 7

Just add everything in the `SpringIndicator.swift` file to your project.

## Usage

### import

If target is ios8.0 or later, please import the `SpringIndicator`.

```Swift
import SpringIndicator
```

### Example

Add Code

```swift
let indicator = SpringIndicator(frame: CGRect(x: 100, y: 100, width: 60, height: 60))
view.addSubview(indicator)
indicator.startAnimation()
```

Refresher

```swift
let refreshControl = SpringIndicator.Refresher()
refreshControl.addTarget(self, action: "onRefresh", forControlEvents: .ValueChanged)
scrollView.addSubview(refreshControl)
```

Exit refresh

```swift
refreshControl.endRefreshing()
```

Can use Interface Builder

![Interface Builder](https://github.com/KyoheiG3/assets/blob/master/SpringIndicator/interface_builder.png)


### Variable

#### Indicator

```swift
@IBInspectable var animating: Bool
```
* Start the animation automatically in `drawRect`.

```swift
@IBInspectable var lineWidth: CGFloat
```
* Line thickness.

```swift
@IBInspectable var lineColor: UIColor
```
* Line Color.
* Default is `gray`.

```swift
@@IBInspectable var lineCap: Bool
```
* Cap style.
* Options are `round` or `square`. true is `round`.
* Default is `false`.

```swift
@IBInspectable var rotateDuration: Double
```
* Rotation duration.
* Default is `1.5`.

```swift
@IBInspectable var strokeDuration: Double
```
* Stroke duration.
* Default is `0.7`.

#### Refresher

```swift
let indicator: SpringIndicator
```
* Refresher Indicator.

```swift
var refreshing: Bool
```
* Refreshing status.


### Function

#### Indicator

```swift
func isSpinning() -> Bool
```
* During stroke animation is `true`.

```swift
func startAnimation(expand: Bool = default)
```
* If start from a state in spread is `true`.

```swift
func stopAnimation(waitAnimation: Bool, completion: ((SpringIndicator.SpringIndicator) -> Void)? = default)
```
* `true` is wait for stroke animation.

```swift
func strokeRatio(ratio: CGFloat)
```
* between `0.0` and `1.0`.

#### Refresher

```swift
func endRefreshing()
```
* Must be explicitly called when the refreshing has completed.

## LICENSE

Under the MIT license. See LICENSE file for details.
