//
//  CSRSSFeedItem.h
//  CSFeedKit
//
//  Created by Cătălin Stan on 31/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CSFeedItem.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  The `CSRSSFeedItem` class represents an RSS feed item.
 */
@interface CSRSSFeedItem : CSFeedItem

/**
 *  The creator of the feed.
 *
 *  @see ["http://purl.org/dc/elements/1.1/]("http://purl.org/dc/elements/1.1/)
 */
@property (nonatomic, strong, nullable) NSString * creator;

@end

NS_ASSUME_NONNULL_END