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
#import "CWBlogImage.h"
#import "CWImageSize.h"
#import "CWAppDelegate.h"

@interface CWBlogRSSController ()

@property (nonatomic, strong) NSPredicate* fetchPredicate;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) CSRSSFeed * feed;
@property (nonatomic, strong) CSRSSFeedChannel * channel;

@end

@implementation CWBlogRSSController

- (instancetype)initWithPrefix:(NSString *)prefix {
    self = [super initWithPrefix:prefix];
    if ( self != nil ) {
        _feed = [[CSRSSFeed alloc] init];
        _channel = [[CSRSSFeedChannel alloc] init];
        _feed.channels = @[self.channel];
        _fetchPredicate = [NSPredicate predicateWithFormat:@"published = true"];
        [self setupRoutes];
    }
    return self;
}

- (void)setupRoutes {

    CWBlogRSSController * __weak controller = self;

    // Generates the fetchPredicate used for the post archive
    CRRouteBlock archiveBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        // Get the month and year from the path
        NSUInteger year = (request.query[@"year"] ? : request.query[@"0"]).integerValue;
        NSUInteger month = (request.query[@"month"] ? : request.query[@"1"]).integerValue;
        
        CWBlogArchivePeriod period = [CWBlog parseYear:year month:month];
        if (!period.year) {
            completionHandler();
            return;
        }
        
        // Build a predicate
        CWBlogDatePair *datePair = [CWBlog datePairArchivePeriod:period];
        controller.fetchPredicate = [NSPredicate predicateWithFormat:@"date >= %@ and date <= %@", datePair.startDate, datePair.endDate];
        
        // Set the page title
        NSString* humanReadableMonth = @"";
        if (!period.month) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MMMM"];
            humanReadableMonth = [NSString stringWithFormat:@" %@", [formatter stringFromDate:datePair.startDate]];
        }
        NSString* humanReadableYear = period.year > 0 ? [NSString stringWithFormat:@" %lu", period.year] : @"";
        controller.title = [NSString stringWithFormat:@"Posts Archive for%@%@", humanReadableMonth, humanReadableYear];
        completionHandler();
    }};

    // Generates the fetchPredicate used for the tag post list
    CRRouteBlock tagBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString* handle = request.query[@"tag"];
        controller.fetchPredicate = [NSPredicate predicateWithFormat:@"tags.handle = %@", handle];
        CWBlogTag* tag;
        if ((tag = [CWBlogTag getByHandle:handle])) {
            controller.title = [NSString stringWithFormat:@"Post with Tag %@", tag.name];
        }
        completionHandler();
    }};

    // Generates the fetchPredicate used for the author post list
    CRRouteBlock authorBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString* handle = request.query[@"author"];
        controller.fetchPredicate = [NSPredicate predicateWithFormat:@"author.handle = %@", handle];
        CWBlogAuthor* author;
        if ((author = [CWBlogAuthor getByHandle:handle])) {
            controller.title = [NSString stringWithFormat:@"Post by %@", author.displayName];
        }
        completionHandler();
    }};

    // Actually fetches the posts according to the fetchPredicate and displays the list
    CRRouteBlock enumeratePostsBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        RLMResults* posts = [[CWBlogPost getObjectsWithPredicate:controller.fetchPredicate] sortedResultsUsingKeyPath:@"publishedDate" ascending:NO];
        controller.channel.pubDate = ((CWBlogPost*)posts.firstObject).publishedDate;
        NSMutableArray<CSRSSFeedItem *> *items = [NSMutableArray arrayWithCapacity:posts.count];
        for (CWBlogPost *post in posts) {
            CSRSSFeedItem *item = [[CSRSSFeedItem alloc] initWithTitle:post.title link:[post permalinkForRequest:request] description:post.renderedContent];
            item.creator = post.author.displayName;
            item.pubDate = post.publishedDate;
            
            CWBlogImage *image;
            if ((image = post.image)) {
                item.enclosure = [[CSRSSFeedItemEnclosure alloc] initWithURL:[image permalinkForRequest:request] length:image.filesize.integerValue type:image.mimeType];
            }
            [items addObject:item];
        }
        controller.channel.items = items;
        completionHandler();
    }};

    // Displays the output
    CRRouteBlock outputBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        controller.channel.title = @"Criollo Blog";
        if (controller.title.length) {
            controller.channel.title = [NSString stringWithFormat:@"%@ - %@", controller.channel.title, controller.title];
        }
        controller.channel.link = [CWAppDelegate baseURL].absoluteString;
        
        NSString *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/criollo-icon-square-padded.png", CWStaticDirPath] relativeToURL:CWAppDelegate.baseURL].absoluteString;
        controller.channel.image = [[CSRSSFeedChannelImage alloc] initWithURL:imageURL title:controller.channel.link link:CWAppDelegate.baseURL.absoluteString];
        [response sendData:controller.feed.XMLDocument.XMLData];
    }};

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
