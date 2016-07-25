//
//  CWBlogAuthor+CoreDataProperties.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "CWBlogAuthor.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogAuthor (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *user;
@property (nullable, nonatomic, retain) NSString *displayName;
@property (nullable, nonatomic, retain) NSString *email;
@property (nullable, nonatomic, retain) NSString *handle;
@property (nullable, nonatomic, retain) NSSet<NSManagedObject *> *posts;

@end

@interface CWBlogAuthor (CoreDataGeneratedAccessors)

- (void)addPostsObject:(NSManagedObject *)value;
- (void)removePostsObject:(NSManagedObject *)value;
- (void)addPosts:(NSSet<NSManagedObject *> *)values;
- (void)removePosts:(NSSet<NSManagedObject *> *)values;

@end

NS_ASSUME_NONNULL_END
