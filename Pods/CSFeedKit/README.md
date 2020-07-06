[![Version Status](https://img.shields.io/cocoapods/v/CSFeedKit.svg?style=flat)](http://cocoadocs.org/docsets/CSFeedKit)  [![Platform](http://img.shields.io/cocoapods/p/CSFeedKit.svg?style=flat)](http://cocoapods.org/?q=CSFeedKit) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![MIT License](https://img.shields.io/badge/license-MIT-orange.svg?style=flat)](https://opensource.org/licenses/MIT)

# CSFeedKit

An RSS feed generator and parser for macOS. Swift and Objective-C compatible.

## Installation

Install using [CocoaPods](http://cocoapods.org) by adding this line to your Podfile:

````ruby
use_frameworks!

target 'MyApp' do
  pod 'CSFeedKit'
end
````

## Creating an RSS Feed

The example below creates an RSS feed and prints the resulting XML string.

```swift

// Create a channel
let channel = CSRSSFeedChannel.init(title: "My RSS feed", link: "http://my.rss.feed/", description: "My first CSFeedKit RSS feed")
channel.category = "Examples"

// Add an item to the channel
let item = CSRSSFeedItem(title: "Item" , link: "http://my.rss.feed/item", description: "The coolest item so far.");
item1.creator = NSFullUserName()
channel.items.addObject(item)

// Create the feed
let feed = CSRSSFeed()

// Add the channel to the feed
feed.channels.addObject(channel)

// Output the XML
print ( feed.XMLDocument().XMLStringWithOptions(NSXMLNodePrettyPrint))
```

## Parsing an RSS feed

The following prints out the titles and URLs of the items in the [Hacker News RSS feed](https://news.ycombinator.com/rss).

```swift
do {
	// Get the XML string (don't do it like this in the real-world ;) )
	let xmlString = try NSString.init(contentsOfURL: NSURL(string: "https://news.ycombinator.com/rss")!, encoding: NSUTF8StringEncoding)
	
	// Init the feed
	let feed = try CSRSSFeed.init(XMLString: xmlString as String)
	
	// Print channel info
	let channel = feed.channels.firstObject as! CSRSSFeedChannel
	print("channel: \(channel.title)")
	
	// Print the items
	for (_, item) in channel.items.enumerate() {
		var rssItem = item as! CSRSSFeedItem
		print(" * \(rssItem.pubDate) - \(rssItem.title) (\(rssItem.link))")
	}
} catch {
	print(error)
}
```

## What’s Next

Run the built-in example: [https://github.com/thecatalinstan/CSFeedKit/blob/master/CSFeedKitExamples/CSFeedKitExamples/main.swift](https://github.com/thecatalinstan/CSFeedKit/blob/master/CSFeedKitExamples/CSFeedKitExamples/main.swift)

Check out the complete documentation on [CocoaDocs](http://cocoadocs.org/docsets/CSFeedKit/).
