//
//  CWAPIBlogAuthor.h
//  Criollo Web
//
//  Created by Cătălin Stan on 16/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CWUser, CWAPIBlogPost;

@interface CWAPIBlogAuthor : CWModel

@property (nullable, nonatomic, retain) NSString<Optional> *user;
@property (nullable, nonatomic, retain) NSString<Optional> *displayName;
@property (nullable, nonatomic, retain) NSString<Optional> *email;
@property (nullable, nonatomic, strong) NSString<Optional> *handle;
@property (nullable, nonatomic, retain) NSSet<CWAPIBlogPost *><Optional> *posts;

@end

NS_ASSUME_NONNULL_END
