//
//  CWBlogPost.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogPost.h"
#import "CWBlogAuthor.h"
#import "CWBlogTag.h"
#import "CWBlog.h"
#import "CWAPIBlogPost.h"
#import "CWAPIBlogAuthor.h"
#import "CWAPIBlogTag.h"
#import "CWUser.h"


@implementation CWBlogPost

#pragma mark - Realm

+ (NSArray<NSString *> *)indexedProperties {
    static NSMutableArray<NSString *> *indexedProperties;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        indexedProperties = [NSMutableArray arrayWithArray:[[self superclass] indexedProperties]];
        [indexedProperties addObjectsFromArray:@[@"title", @"date"]];
    });
    return indexedProperties;
}

#pragma mark - API

- (NSString *)publicPath {
    NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth|NSCalendarUnitYear fromDate:self.date];
    return [NSString stringWithFormat:@"%@/%ld/%s%ld/%@", CWBlogPath, (long)dateComponents.year, dateComponents.month < 10 ? "0" : "", (long)dateComponents.month, self.handle];
}

#pragma mark - CWModelProxy

- (CWModel *)modelObject {
    CWAPIBlogPost* post = [[CWAPIBlogPost alloc] init];
    post.uid = self.uid;
    post.publicPath = self.publicPath;
    post.date = self.date;
    post.title = self.title;
    post.content = self.content;
    post.renderedContent = self.renderedContent;
    post.excerpt = self.excerpt;
    post.author = (CWAPIBlogAuthor *)self.author.modelObject;
    post.handle = self.handle;
    post.tags = [NSMutableArray array];
    for (CWBlogTag* tag in self.tags) {
        [((NSMutableArray *)post.tags) addObject:tag.modelObject];
    }
    return post;
}

#pragma mark - Fetching

+ (instancetype)getByHandle:(NSString *)handle year:(NSUInteger)year month:(NSUInteger)month {
    CWBlogArchivePeriod period = [CWBlog parseYear:year month:month];
    if ( period.year == 0 || period.month == 0 ) {
        return [CWBlogPost getByHandle:handle];
    }
    CWBlogDatePair* datePair = [CWBlog datePairArchivePeriod:period];
    return [CWBlogPost getSingleObjectWhere:@"handle = %@ and date >= %@ and date <= %@", handle, datePair.startDate, datePair.endDate];
}

@end
