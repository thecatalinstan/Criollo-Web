//
//  CSFeedChannel.h
//  CSFeedKit
//
//  Created by Cătălin Stan on 31/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CSFeedItem;

NS_ASSUME_NONNULL_BEGIN

/**
 *  The `CSFeedChannel` class serves as the base class for any feed channel. It
 *  encapsulates those properties found in most types of XML feeds.
 */
@interface CSFeedChannel : NSObject

/**
 *  The title of the channel
 */
@property (nonatomic, strong) NSString * title;

/**
 *  The URL of the channel
 */
@property (nonatomic, strong) NSString * link;

/**
 *  The description of the channel
 */
@property (nonatomic, strong) NSString * channelDescription;

/**
 *  The date when the channel was last rebuild
 */
@property (nonatomic, strong) NSDate * lastBuildDate;

/**
 *  The date when the channel was published
 */
@property (nonatomic, strong) NSDate * pubDate;

/**
 *  The generator of the channel
 */
@property (nonatomic, strong) NSString * generator;

/**
 *  The language of the channel
 */
@property (nonatomic, strong) NSString * language;

/**
 *  The items in the channel
 */
@property (nonatomic, strong) NSMutableArray<CSFeedItem *> * items;

/**
 *  The number of seconds the channel can be safely cached
 */
@property (nonatomic) NSUInteger ttl;

/**
 *  The category of the channel
 */
@property (nonatomic, strong, nullable) NSString * category;

/**
 *  @name Creating a new `CSFeedChannel`
 */

/**
 *  Creates a new `CSFeedChannel` with the specified properties.
 *
 *  @param title       The channel's title
 *  @param link        The URL of the channel
 *  @param description The description of the channel
 *
 *  @return A new `CSFeedChannel`
 */
- (instancetype)initWithTitle:(NSString *)title link:(NSString *)link description:(NSString *)description NS_DESIGNATED_INITIALIZER;

/**
 *  @name Creating a `CSFeedChannel` from XML
 */

/**
 *  Parses an `NSXMLElement` and creates a new `CSFeedChannel` from its contents.
 *
 *  @param element The `NSXMLElement` containing the feed channel
 *
 *  @return A new `CSFeedChannel`
 */
- (instancetype)initWithXMLElement:(NSXMLElement *)element;

/**
 *  Parses an XML string and creates a new `CSFeedChanel` from its contents.
 *
 *  @param string The string containing the feed channel
 *  @param error  Any parsing errors are stored here
 *
 *  @return A new `CSFeedChannel`
 */
- (nullable instancetype)initWithXMLString:(NSString *)string error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
 *  @name Generating XML
 */

/**
 *  Generates an XML element containing the channel's XML representation.
 *
 *  @return An `NSXMLElement` containing the channel's data.
 */

- (NSXMLElement *)XMLElement;

@end

NS_ASSUME_NONNULL_END