//
//  CSFeedItem.h
//  CSFeedKit
//
//  Created by Cătălin Stan on 30/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  The `CSFeedItem` class serves as the base class for any feed item. It
 *  encapsulates those properties found in most types of XML feeds.
 */
@interface CSFeedItem : NSObject

/**
 *  The title of the item.
 */
@property (nonatomic, strong) NSString * title;

/**
 *  The URL of the item.
 */
@property (nonatomic, strong) NSString * link;

/**
 *  The description of the item.
 */
@property (nonatomic, strong) NSString * itemDescription;

/**
 *  The globally unique identifier of the item.
 */
@property (nonatomic, strong) NSString * GUID;

/**
 *  Determines the valie of the `isPermalink` attribute.
 */
@property (nonatomic, assign) BOOL GUIDIsPermaLink;

/**
 *  The link to the comments of the item.
 */
@property (nonatomic, strong, nullable) NSString * comments;

/**
 *  The value of the `info` element.
 */
@property (nonatomic, strong, nullable) NSString * info;

/**
 *  The date when the item was published
 */
@property (nonatomic, strong) NSDate * pubDate;

/**
 *  @name Creating a new `CSFeedItem`
 */

/**
 *  Creates a new `CSFeedItem` with the specified properties.
 *
 *  @param title       The item's title
 *  @param link        The URL of the item
 *  @param description The description of the item
 *
 *  @return A new `CSFeedItem`
 */
- (instancetype)initWithTitle:(NSString *)title link:(NSString *)link description:(NSString *)description NS_DESIGNATED_INITIALIZER;


/**
 *  @name Creating a `CSFeedItem` from XML
 */

/**
 *  Parses an `NSXMLElement` and creates a new `CSFeedItem` from its contents.
 *
 *  @param element The `NSXMLElement` containing the feed item
 *
 *  @return A new `CSFeedItem`
 */
- (instancetype)initWithXMLElement:(NSXMLElement *)element;

/**
 *  Parses an XML string and creates a new `CSFeedItem` from its contents.
 *
 *  @param string The string containing the feed item
 *  @param error  Any parsing errors are stored here
 *
 *  @return A new `CSFeedItem`
 */
- (nullable instancetype)initWithXMLString:(NSString *)string error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
 *  @name Generating XML
 */

/**
 *  Generates an XML element containing the item's XML representation.
 *
 *  @return An `NSXMLElement` containing the item's data.
 */
- (NSXMLElement *)XMLElement;

@end

NS_ASSUME_NONNULL_END