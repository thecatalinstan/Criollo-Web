[![Version Status](https://img.shields.io/cocoapods/v/CSOddFormatters.svg?style=flat)](http://cocoadocs.org/docsets/CSOddFormatters)  [![Platform](http://img.shields.io/cocoapods/p/CSOddFormatters.svg?style=flat)](http://cocoapods.org/?q=CSOddFormatters) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![MIT License](https://img.shields.io/badge/license-MIT-orange.svg?style=flat)](https://opensource.org/licenses/MIT)

# CSOddFormatters

A collection of useful `NSFormatter` subclasses. The purpose of these formatters is to provide either missing functionality or to make the existing `NSFormatters` reliable for use in a high-concurrency multi-threaded environments such as that of a web-server.

I’ve used these formatters when making the [criollo.io](https://criollo.io) website in order to format the number of requests served and the time the app has been running.

Here’s what’s in the package:

- `CSLargeNumberFormatter` - formats large numbers to a more human-readable number format. Instead of 1450000 it will output 1.4 M and so on.
- `CSTimeIntervalFormatter` - makes it a bit easier and more reliable to format time intervals.

## Getting Started

### Installation through CocoaPods

Install using [CocoaPods](http://cocoapods.org) by adding this line to your Podfile:

````ruby
use_frameworks!

target 'MyApp' do
  pod 'CSOddFormatters', '~> 1.0’
end
````

### In your Project

```swift
import CSOddFormatters

print("\(CSLargeNumberFormatter.stringFromNumber(123456789))")
```

## CSLargeNumberFormatter

The preffered way of using it is through the class methods `stringFromNumber:` and `numberFromString:`, but it can also be used as any regular `NSNumberFormatter`.

```swift
import CSOddFormatters

print(CSLargeNumberFormatter.stringFromNumber(123456789))
print(CSLargeNumberFormatter.numberFromString("123.5 M"))
```

Check out the complete reference at [http://cocoadocs.org/docsets/CSOddFormatters/1.0.0/Classes/CSLargeNumberFormatter.html](http://cocoadocs.org/docsets/CSOddFormatters/1.0.0/Classes/CSLargeNumberFormatter.html)

## CSTimeIntervalFormatter

The preffered way of using it is through the class methods `stringFromTimeInterval:`, `stringFromDate:toDate:` and `stringFromDateComponents:`, but it can also be used as any regular NSDateComponentsFormatter.

```swift
print(NSTimeIntervalFormatter.stringFromTimeInterval(3600))

print(NSTimeIntervalFormatter.stringFromDate(NSDate.distantPast(), toDate:NSDate.distantFuture))
```

Check out the complete reference at [http://cocoadocs.org/docsets/CSOddFormatters/1.0.0/Classes/CSTimeIntervalFormatter.html](http://cocoadocs.org/docsets/CSOddFormatters/1.0.0/Classes/CSTimeIntervalFormatter.html)

## What’s Next

Check out the complete documentation on [CocoaDocs](http://cocoadocs.org/docsets/CSOddFormatters/).
