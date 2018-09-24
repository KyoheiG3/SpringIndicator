# SpringIndicator

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/SpringIndicator.svg?style=flat)](http://cocoadocs.org/docsets/SpringIndicator)
[![License](https://img.shields.io/cocoapods/l/SpringIndicator.svg?style=flat)](http://cocoadocs.org/docsets/SpringIndicator)
[![Platform](https://img.shields.io/cocoapods/p/SpringIndicator.svg?style=flat)](http://cocoadocs.org/docsets/SpringIndicator)

#### [Appetize's Demo](https://appetize.io/app/taw1k1486yhxqy35gv7jrver7g)

* Refresher is a simple as UIRefreshControl.
* Don't need to add a UIScrollView delegate.

![Indicator](https://raw.githubusercontent.com/KyoheiG3/assets/master/SpringIndicator/indicator.gif)
![Refresher](https://raw.githubusercontent.com/KyoheiG3/assets/master/SpringIndicator/refresher.gif)

![Image](https://raw.githubusercontent.com/KyoheiG3/assets/master/SpringIndicator/refresher.png)


## Requirements

- Swift 4.2
- iOS 8.0 or later
- tvOS 9.0 or later

## How to Install SpringIndicator

#### Cocoapods

Add the following to your `Podfile`:

```Ruby
pod "SpringIndicator"
```

#### Carthage

Add the following to your `Cartfile`:

```Ruby
github "KyoheiG3/SpringIndicator"
```

## Usage

### Example

Add Code

```swift
let indicator = SpringIndicator(frame: CGRect(x: 100, y: 100, width: 60, height: 60))
view.addSubview(indicator)
indicator.start()
```

RefreshIndicator

```swift
let refreshControl = RefreshIndicator()
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
var lineColors: [UIColor]
```
* Line Colors.
* Can change some colors during rotation.
* If set, `lineColor` is not used.

```swift
@IBInspectable var lineCap: Bool
```
* Cap style.
* Options are `round` or `square`. true is `round`.
* Default is `false`.

```swift
@IBInspectable var rotateDuration: Double
```
* Rotation duration.
* Default is `1.5`.

#### RefreshIndicator

```swift
let indicator: SpringIndicator
```
* Indicator for refresh control.

```swift
var isRefreshing: Bool
```
* Refreshing status.


### Function

#### Indicator

```swift
var isSpinning: Bool
```
* During stroke animation is `true`.

```swift
func start()
```
* Start animating.

```swift
func stop(with: Bool = default, completion: ((SpringIndicator) -> Swift.Void)? = default)
```
* Stop animating.
* If true, waiting for stroke animation.

```swift
func strokeRatio(_ ratio: CGFloat)
```
* between `0.0` and `1.0`.

#### Refresher

```swift
func endRefreshing()
```
* Must be explicitly called when the refreshing has completed.

## Author

#### Kyohei Ito

- [GitHub](https://github.com/kyoheig3)
- [Twitter](https://twitter.com/kyoheig3)

Follow me 🎉

## LICENSE

Under the MIT license. See LICENSE file for details.
