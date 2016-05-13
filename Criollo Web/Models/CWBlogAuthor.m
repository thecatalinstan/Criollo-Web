//
//  CWBlogAuthor.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogAuthor.h"

@implementation CWBlogAuthor

+ (instancetype)fetchAuthorForUsername:(NSString *)username inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([CWBlogAuthor class]) inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user=%@", username];
    [fetchRequest setPredicate:predicate];

    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:error];
    if (fetchedObjects != nil) {
        return fetchedObjects.firstObject;
    }

    return nil;
}

@end
