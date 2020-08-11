//
//  CWBlogPost.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWSchema.h"
#import "CWBlogTag.h"

@class CWBlogAuthor, CWBlogImage;

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogPost : CWSchema

@property NSDate * publishedDate;
@property NSDate * lastUpdatedDate;
@property NSString * title;
@property NSString * content;
@property NSString * renderedContent;
@property NSString * excerpt;
@property CWBlogAuthor * author;
@property RLMArray<CWBlogTag *><CWBlogTag> * tags;
@property CWBlogImage *image;
@property BOOL published;

+ (nullable instancetype)getByHandle:(NSString *)handle year:(NSUInteger)year month:(NSUInteger)month;

@end

NS_ASSUME_NONNULL_END
