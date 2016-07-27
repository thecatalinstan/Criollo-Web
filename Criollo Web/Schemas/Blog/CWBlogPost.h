//
//  CWBlogPost.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWSchema.h"
#import "CWBlogTag.h"

@class CWBlogAuthor;

@interface CWBlogPost : CWSchema

@property NSDate * date;
@property NSString * title;
@property NSString * content;
@property NSString * renderedContent;
@property CWBlogAuthor * author;
@property RLMArray<CWBlogTag *><CWBlogTag> * tags;

@end