//
//  CSFeed.h
//  CSFeedKit
//
//  Created by Cătălin Stan on 31/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CSFeedChannel;

NS_ASSUME_NONNULL_BEGIN

/**
 *  The `CSFeed` class serves as the base class for any feed. It encapsulates
 *  those properties found in most types of XML feeds.
 */
@interface CSFeed : NSObject

/**
 *  The version of the feed.
 */
@property (nonatomic, strong, nullable) NSString * version;

/**
 *  The namespaces associated with the feed.
 */
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> * namespaces;

/**
 *  The channels of the feed.
 */
@property (nonatomic, strong) NSMutableArray<CSFeedChannel *> * channels;

/**
 *  The name of the XML node used to output the feed. (Defaults to `feed`)
 */
@property (nonatomic, strong) NSString * nodeName;

/**
 *  @name Creating a new `CSFeed`
 */

/**
 *  Creates a new `CSFeed` with the specified node name.
 *
 *  @param nodeName The node name to use for the resulting XML.
 *
 *  @return A new `CSFeed` object.
 */
- (instancetype)initWithNodeName:(NSString * _Nullable)nodeName NS_DESIGNATED_INITIALIZER;

/**
 *  Parses an `NSXMLElement` and creates a new `CSFeed` from its contents.
 *
 *  @param element The `NSXMLElement` containing the feed.
 *
 *  @return A new `CSFeed` object.
 */
- (instancetype)initWithXMLElement:(NSXMLElement *)element;

/**
 *  Parses an `NSXMLDocument` and creates a new `CSFeed` from its contents.
 *
 *  @param document The `NSXMLDocument` containing the feed.
 *
 *  @return A new `CSFeed` object.
 */
- (instancetype)initWithXMLDocument:(NSXMLDocument *)document;

/**
 *  Parses an XML string and creates a new `CSFeed` from its contents.
 *
 *  @param string The string containing the feed.
 *  @param error  Any XML parsing errors are returned in this parameter.
 *
 *  @return A new `CSFeed` object.
 */
- (nullable instancetype)initWithXMLString:(NSString *)string error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
 *  @name Generating XML
 */

/**
 *  Generates an XML element containing the feed's XML representation.
 *
 *  @return An `NSXMLElement` containing the feed data.
 */
- (NSXMLElement *)XMLElement;

/**
 *  Generates an XML document containing the feed's XML representation.
 *
 *  @return An `NSXMLDocument` containing the feed data.
 */
- (NSXMLDocument *)XMLDocument;

@end

NS_ASSUME_NONNULL_END