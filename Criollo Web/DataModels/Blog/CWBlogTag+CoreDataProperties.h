//
//  CWBlogTag+CoreDataProperties.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "CWBlogTag.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogTag (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSSet<NSManagedObject *> *posts;

@end

@interface CWBlogTag (CoreDataGeneratedAccessors)

- (void)addPostsObject:(NSManagedObject *)value;
- (void)removePostsObject:(NSManagedObject *)value;
- (void)addPosts:(NSSet<NSManagedObject *> *)values;
- (void)removePosts:(NSSet<NSManagedObject *> *)values;

@end

NS_ASSUME_NONNULL_END
