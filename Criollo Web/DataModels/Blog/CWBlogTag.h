//
//  CWBlogTag.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CWAPIBlogTag;

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogTag : NSManagedObject

@property (nonatomic, readonly, copy) CWAPIBlogTag* APIBlogTag;

+ (nullable instancetype)fetchTagForName:(NSString *)name error:(NSError * __autoreleasing *)error;
+ (instancetype)blogTagFromAPIBlogTag:(CWAPIBlogTag *)tag;

@end

NS_ASSUME_NONNULL_END

#import "CWBlogTag+CoreDataProperties.h"
