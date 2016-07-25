//
//  CWBlogPost.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogPost.h"
#import "CWBlogAuthor.h"
#import "CWBlogTag.h"
#import "CWBlog.h"
#import "CWAppDelegate.h"
#import "CWAPIBlogPost.h"
#import "CWAPIBlogAuthor.h"
#import "CWAPIBlogTag.h"
#import "CWUser.h"

@interface CWBlogPost () {
    NSString * _path;
    dispatch_once_t _pathOnceToken;
}

@end

@implementation CWBlogPost

- (NSString *)publicPath {
    NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth|NSCalendarUnitYear fromDate:self.date];
    return [NSString stringWithFormat:@"%@/%ld/%ld/%@", CWBlogPath, (long)dateComponents.year, (long)dateComponents.month, self.handle];
}

- (CWAPIBlogPost *)APIBlogPost {
    CWAPIBlogPost* apiBlogPost = [[CWAPIBlogPost alloc] init];
    apiBlogPost.uid = self.objectID.URIRepresentation.absoluteString;
    apiBlogPost.publicPath = self.publicPath;
    apiBlogPost.date = self.date;
    apiBlogPost.title = self.title;
    apiBlogPost.content = self.content;
    apiBlogPost.renderedContent = self.renderedContent;
    apiBlogPost.author = self.author.APIBlogAuthor;
    apiBlogPost.handle = self.handle;

    NSMutableSet* tags = [NSMutableSet set];
    [self.tags enumerateObjectsUsingBlock:^(CWBlogTag * _Nonnull obj, BOOL * _Nonnull stop) {
        [tags addObject:obj.APIBlogTag];
    }];
    apiBlogPost.tags = tags;

    return apiBlogPost;
}

+ (instancetype)blogPostWithHandle:(NSString *)handle {
    return [CWBlogPost blogPostWithHandle:handle year:0 month:0];
}

+ (instancetype)blogPostWithHandle:(NSString *)handle year:(NSUInteger)year {
    return [CWBlogPost blogPostWithHandle:handle year:year month:0];
}

+ (instancetype)blogPostWithHandle:(NSString *)handle year:(NSUInteger)year month:(NSUInteger)month {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CWBlogPost" inManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
    [fetchRequest setEntity:entity];

    NSPredicate *predicate;
    if ( year == 0 || month == 0 ) {
        predicate = [NSPredicate predicateWithFormat:@"handle = %@", handle];
    } else {
        NSDate* startDate = [[NSCalendar currentCalendar] dateWithEra:1 year:year month:month day:1 hour:0 minute:0 second:0 nanosecond:0];
        if ( month == 12 ) {
            year++;
            month = 1;
        } else {
            month++;
        }
        NSDate* endDate = [[[NSCalendar currentCalendar] dateWithEra:1 year:year month:month day:1 hour:0 minute:0 second:0 nanosecond:0] dateByAddingTimeInterval:-1];
        predicate = [NSPredicate predicateWithFormat:@"handle = %@ and date >= %@ and date <= %@", handle, startDate, endDate];
    }
    [fetchRequest setPredicate:predicate];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

    CWBlogPost * post;
    NSArray *fetchedObjects = [[CWAppDelegate sharedBlog].managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects.count > 0) {
        post = fetchedObjects.firstObject;
    }
    return post;
}

+ (NSArray<CWBlogPost *> *)fetchBlogPostsWithPredicate:(NSPredicate *)predicate error:(NSError *__autoreleasing  _Nullable *)error {

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CWBlogPost" inManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
    [fetchRequest setEntity:entity];

    if ( predicate != nil ) {
        [fetchRequest setPredicate:predicate];
    }

    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

    NSArray<CWBlogPost *> * posts = [[CWAppDelegate sharedBlog].managedObjectContext executeFetchRequest:fetchRequest error:error];
    return posts;
}


+ (instancetype)blogPostFromAPIBlogPost:(CWAPIBlogPost *)post {
    CWBlogPost* newPost;
    if ( post.uid ) {
        NSURL* postIdURIRepresentation = [NSURL URLWithString:post.uid];
        if ( postIdURIRepresentation ) {
            NSManagedObjectID* postId = [[CWAppDelegate sharedBlog].managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:postIdURIRepresentation];
            if ( postId ) {
                NSError* coreDataError = nil;
                newPost = [[CWAppDelegate sharedBlog].managedObjectContext existingObjectWithID:postId error:&coreDataError];
                if ( coreDataError ) {
                    [CRApp logErrorFormat:@"Unable to get managed object from id: %@", coreDataError.localizedDescription];
                }
            }
        }
    }

    if ( newPost == nil ) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"CWBlogPost" inManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
        newPost = [[CWBlogPost alloc] initWithEntity:entity insertIntoManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];;
    }

    newPost.date = post.date;
    newPost.handle = post.handle;
    newPost.title = post.title;
    newPost.content = post.content;
    newPost.renderedContent = post.renderedContent;

    if ( post.author ) {
        CWBlogAuthor* author = [CWBlogAuthor authorWithUsername:post.author.user];
        if ( !author ) {
            author = [CWBlogAuthor blogAuthorFromAPIBlogAuthor:post.author];
        }
        newPost.author = author;
    }

    NSMutableSet* tags = [NSMutableSet set];
    [post.tags enumerateObjectsUsingBlock:^(CWAPIBlogTag * _Nonnull obj, BOOL * _Nonnull stop) {
        CWBlogTag* tag = [CWBlogTag tagWithHandle:obj.handle];
        if ( !tag ) {
            tag = [CWBlogTag blogTagFromAPIBlogTag:obj];
        }
        [tags addObject:tag];
    }];
    newPost.tags = tags;
    return newPost;

}


@end
