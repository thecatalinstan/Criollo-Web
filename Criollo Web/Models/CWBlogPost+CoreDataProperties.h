//
//  CWBlogPost+CoreDataProperties.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "CWBlogPost.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogPost (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSString *handle;
@property (nullable, nonatomic, retain) NSString *content;
@property (nullable, nonatomic, retain) NSString *rendered_content;
@property (nullable, nonatomic, retain) CWBlogAuthor *author;
@property (nullable, nonatomic, retain) NSSet<CWBlogTag *> *tags;

@end

@interface CWBlogPost (CoreDataGeneratedAccessors)

- (void)addTagsObject:(CWBlogTag *)value;
- (void)removeTagsObject:(CWBlogTag *)value;
- (void)addTags:(NSSet<CWBlogTag *> *)values;
- (void)removeTags:(NSSet<CWBlogTag *> *)values;

@end

NS_ASSUME_NONNULL_END
