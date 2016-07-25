//
//  CWBlogAuthor.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CWAPIBlogAuthor;

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogAuthor : NSManagedObject

@property (nonatomic, readonly, strong) NSString *publicPath;
@property (nonatomic, readonly, copy) CWAPIBlogAuthor *APIBlogAuthor;

+ (nullable instancetype)authorWithHandle:(NSString *)handle;
+ (nullable instancetype)authorWithUsername:(NSString *)username;

+ (instancetype)blogAuthorFromAPIBlogAuthor:(CWAPIBlogAuthor *)author;

@end

NS_ASSUME_NONNULL_END

#import "CWBlogAuthor+CoreDataProperties.h"
