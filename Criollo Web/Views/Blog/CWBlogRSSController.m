//
//  CWBlogRSSController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 01/08/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <CSFeedKit/CSFeedKit.h>

#import "CWBlogRSSController.h"
#import "CWBlog.h"
#import "CWBlogTag.h"
#import "CWBlogAuthor.h"
#import "CWBlogPost.h"

@interface CWBlogRSSController ()

@property (nonatomic, strong) NSPredicate* fetchPredicate;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) CSRSSFeed * feed;
@property (nonatomic, strong) CSRSSFeedChannel * channel;

@property (nonatomic, strong, readonly) CRRouteBlock archiveBlock;
@property (nonatomic, strong, readonly) CRRouteBlock tagBlock;
@property (nonatomic, strong, readonly) CRRouteBlock authorBlock;
@property (nonatomic, strong, readonly) CRRouteBlock enumeratePostsBlock;
@property (nonatomic, strong, readonly) CRRouteBlock outputBlock;

- (void)setupRoutes;


@end

@implementation CWBlogRSSController

- (instancetype)initWithPrefix:(NSString *)prefix {
    self = [super initWithPrefix:prefix];
    if ( self != nil ) {
        self.channel = [[CSRSSFeedChannel alloc] init];
        self.feed = [[CSRSSFeed alloc] init];
        [self.feed.channels addObject:self.channel];
        [self setupRoutes];
    }
    return self;
}

- (void)setupRoutes {
    
    // Set content-type to XML
    [self add:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"application/rss+xml; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        completionHandler();
    }];

    // Author
    NSString* authorPath = [CWBlogAuthorPath stringByAppendingPathComponent:@":author"];
    [self get:authorPath block:self.authorBlock];
    [self get:authorPath block:self.enumeratePostsBlock];
    [self get:authorPath block:self.outputBlock];

    // Tag
    NSString* tagPath = [CWBlogTagPath stringByAppendingPathComponent:@":tag"];
    [self get:tagPath block:self.tagBlock];
    [self get:tagPath block:self.enumeratePostsBlock];
    [self get:tagPath block:self.outputBlock];

    // Yearly archive
    [self get:CWBlogArchiveYearPath block:self.archiveBlock];
    [self get:CWBlogArchiveYearPath block:self.enumeratePostsBlock];
    [self get:CWBlogArchiveYearPath block:self.outputBlock];

    // Monthly archive
    [self get:CWBlogArchiveYearMonthPath block:self.archiveBlock];
    [self get:CWBlogArchiveYearMonthPath block:self.enumeratePostsBlock];
    [self get:CWBlogArchiveYearMonthPath block:self.outputBlock];

    [self get:@"/" block:self.enumeratePostsBlock];
    [self get:@"/" block:self.outputBlock];
}

/**
 *  Generates the fetchPredicate used for the post archive
 */
- (CRRouteBlock)archiveBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        // Get the month and year from the path
        NSUInteger year = (request.query[@"year"] ? : request.query[@"0"]).integerValue;
        NSUInteger month = (request.query[@"month"] ? : request.query[@"1"]).integerValue;

        CWBlogArchivePeriod period = [CWBlog parseYear:year month:month];
        if ( period.year == 0 ) {
            completionHandler();
            return;
        }

        // Build a predicate
        CWBlogDatePair *datePair = [CWBlog datePairArchivePeriod:period];
        self.fetchPredicate = [NSPredicate predicateWithFormat:@"date >= %@ and date <= %@", datePair.startDate, datePair.endDate];

        // Set the page title
        NSString* humanReadableMonth = @"";
        if ( period.month != 0 ) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MMMM"];
            humanReadableMonth = [NSString stringWithFormat:@" %@", [formatter stringFromDate:datePair.startDate]];
        }
        NSString* humanReadableYear = period.year > 0 ? [NSString stringWithFormat:@" %lu", period.year] : @"";
        self.title = [NSString stringWithFormat:@"Posts Archive for%@%@", humanReadableMonth, humanReadableYear];

        completionHandler();
    };
}

/**
 *  Generates the fetchPredicate used for the tag post list
 */
- (CRRouteBlock)tagBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* handle = request.query[@"tag"];
        self.fetchPredicate = [NSPredicate predicateWithFormat:@"tags.handle = %@", handle];
        CWBlogTag* tag = [CWBlogTag getByHandle:handle];
        if ( tag ) {
            self.title = [NSString stringWithFormat:@"Post with Tag %@", tag.name];
        }
        completionHandler();
    };
}

/**
 *  Generates the fetchPredicate used for the author post list
 */
- (CRRouteBlock)authorBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* handle = request.query[@"author"];
        self.fetchPredicate = [NSPredicate predicateWithFormat:@"author.handle = %@", handle];
        CWBlogAuthor* author = [CWBlogAuthor getByHandle:handle];
        if ( author ) {
            self.title = [NSString stringWithFormat:@"Post by %@", author.displayName];
        }
        completionHandler();
    };
}

/**
 *  Actually fetches the posts according to the fetchPredicate and displays the list
 */
- (CRRouteBlock)enumeratePostsBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        RLMResults* posts = [[CWBlogPost getObjectsWithPredicate:self.fetchPredicate] sortedResultsUsingProperty:@"publishedDate" ascending:NO];
        self.channel.pubDate = ((CWBlogPost*)posts.firstObject).publishedDate;    
        for ( CWBlogPost *post in posts ) {
            CSRSSFeedItem * item = [[CSRSSFeedItem alloc] initWithTitle:post.title link:[post permalinkForRequest:request] description:post.renderedContent];
            item.creator = post.author.displayName;
            item.pubDate = post.publishedDate;
            [self.channel.items addObject:item];
        }
        completionHandler();
    };
}

- (CRRouteBlock)outputBlock {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        self.channel.title = @"Criollo Blog";
        if ( self.title.length > 0 ) {
            self.channel.title = [NSString stringWithFormat:@"%@ - %@", self.channel.title, self.title];
        }
        self.channel.link = @"https://criollo.io/";
        NSData * output = self.feed.XMLDocument.XMLData;
        [response sendData:output];
    };
}

@end
