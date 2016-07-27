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
#import "CWAppDelegate.h"
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
        [indexedProperties addObjectsFromArray:@[@"name"]];
    });
    return indexedProperties;
}

#pragma mark - API

- (NSString *)publicPath {
    NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth|NSCalendarUnitYear fromDate:self.date];
    return [NSString stringWithFormat:@"%@/%ld/%s%ld/%@", CWBlogPath, (long)dateComponents.year, dateComponents.month < 10 ? "0" : "", (long)dateComponents.month, self.handle];
}

@end
