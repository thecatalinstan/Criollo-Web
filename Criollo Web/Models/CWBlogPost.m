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

@interface CWBlogPost () {
    NSString * _path;
    dispatch_once_t _pathOnceToken;
}

@end

@implementation CWBlogPost

- (NSString *)path {
    dispatch_once(&_pathOnceToken, ^{
        NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth|NSCalendarUnitYear fromDate:self.date];
        _path = [NSString stringWithFormat:@"%@/%ld/%ld/%@", CWBlogPath, (long)dateComponents.year, (long)dateComponents.month, self.handle];
    });
    return _path;
}

@end
