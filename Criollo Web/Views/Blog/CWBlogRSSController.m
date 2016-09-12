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
#import "CWAppDelegate.h"

@interface CWBlogRSSController ()

@property (nonatomic, strong) NSPredicate* fetchPredicate;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) CSRSSFeed * feed;
@property (nonatomic, strong) CSRSSFeedChannel * channel;

- (void)setupRoutes;

@end

@implementation CWBlogRSSController

- (instancetype)initWithPrefix:(NSString *)prefix {
    self = [super initWithPrefix:prefix];
    if ( self != nil ) {
        _feed = [[CSRSSFeed alloc] init];
        _channel = [[CSRSSFeedChannel alloc] init];
        [_feed.channels addObject:self.channel];
        _fetchPredicate = [NSPredicate predicateWithFormat:@"published = true"];
        [self setupRoutes];
    }
    return self;
}

- (void)setupRoutes {

    CWBlogRSSController * __weak controller = self;

    // Generates the fetchPredicate used for the post archive
    CRRouteBlock archiveBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        @autoreleasepool {
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
            controller.fetchPredicate = [NSPredicate predicateWithFormat:@"date >= %@ and date <= %@", datePair.startDate, datePair.endDate];

            // Set the page title
            NSString* humanReadableMonth = @"";
            if ( period.month != 0 ) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"MMMM"];
                humanReadableMonth = [NSString stringWithFormat:@" %@", [formatter stringFromDate:datePair.startDate]];
            }
            NSString* humanReadableYear = period.year > 0 ? [NSString stringWithFormat:@" %lu", period.year] : @"";
            controller.title = [NSString stringWithFormat:@"Posts Archive for%@%@", humanReadableMonth, humanReadableYear];
        }
        completionHandler();
    };

    // Generates the fetchPredicate used for the tag post list
    CRRouteBlock tagBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        @autoreleasepool {
            NSString* handle = request.query[@"tag"];
            controller.fetchPredicate = [NSPredicate predicateWithFormat:@"tags.handle = %@", handle];
            CWBlogTag* tag = [CWBlogTag getByHandle:handle];
            if ( tag ) {
                controller.title = [NSString stringWithFormat:@"Post with Tag %@", tag.name];
            }
        }
        completionHandler();
    };

    // Generates the fetchPredicate used for the author post list
    CRRouteBlock authorBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        @autoreleasepool {
            NSString* handle = request.query[@"author"];
            controller.fetchPredicate = [NSPredicate predicateWithFormat:@"author.handle = %@", handle];
            CWBlogAuthor* author = [CWBlogAuthor getByHandle:handle];
            if ( author ) {
                controller.title = [NSString stringWithFormat:@"Post by %@", author.displayName];
            }
        }
        completionHandler();
    };

    // Actually fetches the posts according to the fetchPredicate and displays the list
    CRRouteBlock enumeratePostsBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        @autoreleasepool {
            RLMResults* posts = [[CWBlogPost getObjectsWithPredicate:controller.fetchPredicate] sortedResultsUsingProperty:@"publishedDate" ascending:NO];
            controller.channel.pubDate = ((CWBlogPost*)posts.firstObject).publishedDate;
            for ( CWBlogPost *post in posts ) {
                CSRSSFeedItem * item = [[CSRSSFeedItem alloc] initWithTitle:post.title link:[post permalinkForRequest:request] description:post.renderedContent];
                item.creator = post.author.displayName;
                item.pubDate = post.publishedDate;
                [controller.channel.items addObject:item];
            }
        }
        completionHandler();
    };

    // Displays the output
    CRRouteBlock outputBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        @autoreleasepool {
            controller.channel.title = @"Criollo Blog";
            if ( controller.title.length > 0 ) {
                controller.channel.title = [NSString stringWithFormat:@"%@ - %@", controller.channel.title, controller.title];
            }
            controller.channel.link = [CWAppDelegate baseURL].absoluteString;
            NSData * output = controller.feed.XMLDocument.XMLData;
            [response sendData:output];
        }
    };

    // Set content-type to XML
    [self add:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        @autoreleasepool {
            [response setValue:@"application/rss+xml; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        }
        completionHandler();
    }];

    // Author
    NSString* authorPath = [CWBlogAuthorPath stringByAppendingPathComponent:@":author"];
    [self get:authorPath block:authorBlock];
    [self get:authorPath block:enumeratePostsBlock];
    [self get:authorPath block:outputBlock];

    // Tag
    NSString* tagPath = [CWBlogTagPath stringByAppendingPathComponent:@":tag"];
    [self get:tagPath block:tagBlock];
    [self get:tagPath block:enumeratePostsBlock];
    [self get:tagPath block:outputBlock];

    // Yearly archive
    [self get:CWBlogArchiveYearPath block:archiveBlock];
    [self get:CWBlogArchiveYearPath block:enumeratePostsBlock];
    [self get:CWBlogArchiveYearPath block:outputBlock];

    // Monthly archive
    [self get:CWBlogArchiveYearMonthPath block:archiveBlock];
    [self get:CWBlogArchiveYearMonthPath block:enumeratePostsBlock];
    [self get:CWBlogArchiveYearMonthPath block:outputBlock];

    [self get:CRPathSeparator block:enumeratePostsBlock];
    [self get:CRPathSeparator block:outputBlock];
}

@end
