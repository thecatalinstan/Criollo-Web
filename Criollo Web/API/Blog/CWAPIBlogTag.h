//
//  CWAPIBlogTag.h
//  Criollo Web
//
//  Created by Cătălin Stan on 16/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWModel.h"

@class CWAPIBlogPost;

NS_ASSUME_NONNULL_BEGIN

@interface CWAPIBlogTag : CWModel

@property (nullable, nonatomic, strong) NSString *name;
@property (nullable, nonatomic, strong) NSSet<CWAPIBlogPost *><Optional> *posts;

@end

NS_ASSUME_NONNULL_END
