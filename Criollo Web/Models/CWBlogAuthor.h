//
//  CWBlogAuthor.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogAuthor : NSManagedObject

+ (nullable instancetype)fetchAuthorForUsername:(NSString *)username inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#import "CWBlogAuthor+CoreDataProperties.h"
