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

@property (nonatomic, readonly, copy) CWAPIBlogAuthor* APIBlogAuthor;

+ (nullable instancetype)fetchAuthorForUsername:(NSString *)username error:(NSError * __autoreleasing *)error;
+ (instancetype)blogAuthorFromAPIBlogAuthor:(CWAPIBlogAuthor *)author;

@end

NS_ASSUME_NONNULL_END

#import "CWBlogAuthor+CoreDataProperties.h"
