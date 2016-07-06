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

@interface CWBlogPost () {
    NSString * _path;
    dispatch_once_t _pathOnceToken;
}

@end

@implementation CWBlogPost

- (NSString *)path {
    NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth|NSCalendarUnitYear fromDate:self.date];
    return [NSString stringWithFormat:@"%@/%ld/%ld/%@", CWBlogPath, (long)dateComponents.year, (long)dateComponents.month, self.handle];
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
        NSDate* startDate = [[NSCalendar currentCalendar] dateWithEra:0 year:year month:month day:1 hour:0 minute:0 second:0 nanosecond:0];
        if ( month == 12 ) {
            year++;
            month = 1;
        } else {
            month++;
        }
        NSDate* endDate = [[[NSCalendar currentCalendar] dateWithEra:0 year:year month:month day:1 hour:0 minute:0 second:0 nanosecond:0] dateByAddingTimeInterval:-1];
        predicate = [NSPredicate predicateWithFormat:@"handle = %@ and date >= %@ and date <= %@", handle, startDate, endDate];
    }
    [fetchRequest setPredicate:predicate];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

    __block CWBlogPost * post;

    [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        NSArray *fetchedObjects = [[CWAppDelegate sharedBlog].managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects.count > 0) {
            post = fetchedObjects.firstObject;
        }
    }];

    return post;
}

+ (NSArray<CWBlogPost *> *)blogPostsWithPredicate:(NSPredicate *)predicate error:(NSError *__autoreleasing  _Nullable *)error {

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CWBlogPost" inManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
    [fetchRequest setEntity:entity];

    if ( predicate != nil ) {
        [fetchRequest setPredicate:predicate];
    }

    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

    __block NSArray<CWBlogPost *> * posts;

    [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
        posts = [[CWAppDelegate sharedBlog].managedObjectContext executeFetchRequest:fetchRequest error:error];
    }];

    return posts;
}


@end
