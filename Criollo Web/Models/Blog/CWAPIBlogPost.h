//
//  CWAPIBlogPost.h
//  Criollo Web
//
//  Created by Cătălin Stan on 15/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CWAPIBlogAuthor, CWAPIBlogTag;

@protocol CWAPIBlogTag
@end

@interface CWAPIBlogPost : CWModel

@property (nullable, nonatomic, strong) NSDate<Optional> *publishedDate;
@property (nullable, nonatomic, strong) NSDate<Optional> *lastUpdatedDate;
@property (nullable, nonatomic, strong) NSString<Optional> *title;
@property (nullable, nonatomic, strong) NSString<Optional> *handle;
@property (nullable, nonatomic, strong) NSString<Optional> *content;
@property (nullable, nonatomic, strong) NSString<Optional> *renderedContent;
@property (nullable, nonatomic, strong) NSString<Optional> *excerpt;
@property (nullable, nonatomic, strong) CWAPIBlogAuthor<Optional> *author;
@property (nullable, nonatomic, strong) NSArray<CWAPIBlogTag *><CWAPIBlogTag,Optional> *tags;
@property (nonatomic, assign) BOOL published;

@end

NS_ASSUME_NONNULL_END
