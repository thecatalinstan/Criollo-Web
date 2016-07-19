//
//  CWBlogAuthor.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogAuthor.h"
#import "CWAPIBlogAuthor.h"
#import "CWAppDelegate.h"
#import "CWBlog.h"
#import "CWUser.h"

@implementation CWBlogAuthor

- (NSString *)publicPath {
    return [NSString stringWithFormat:@"%@/%@/%@", CWBlogPath, CWBlogAuthorPredicate, self.user];
}

- (CWAPIBlogAuthor *)APIBlogAuthor {
    CWAPIBlogAuthor *apiBlogAuthor = [[CWAPIBlogAuthor alloc] init];
    apiBlogAuthor.uid = self.objectID.URIRepresentation.absoluteString;
    apiBlogAuthor.publicPath = self.publicPath;
    apiBlogAuthor.displayName = self.displayName;
    apiBlogAuthor.email = self.email;
    apiBlogAuthor.user = self.user;
    return apiBlogAuthor;
}

+ (instancetype)fetchAuthorForUsername:(NSString *)username error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([CWBlogAuthor class]) inManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user=%@", username];
    [fetchRequest setPredicate:predicate];

    __block CWBlogAuthor* author;
    [[CWAppDelegate sharedBlog].managedObjectContext performBlockAndWait:^{
        NSArray *fetchedObjects = [[CWAppDelegate sharedBlog].managedObjectContext executeFetchRequest:fetchRequest error:error];
        if (fetchedObjects != nil) {
            author = fetchedObjects.firstObject;
        }
    }];
    return author;
}

+ (instancetype)blogAuthorFromAPIBlogAuthor:(CWAPIBlogAuthor *)author {
    CWBlogAuthor* newAuthor;
    if ( author.uid ) {
        NSURL* authorIdURIRepresentation = [NSURL URLWithString:author.uid];
        if ( authorIdURIRepresentation ) {
            NSManagedObjectID* authorId = [[CWAppDelegate sharedBlog].managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:authorIdURIRepresentation];
            if ( authorId ) {
                NSError* coreDataError = nil;
                newAuthor = [[CWAppDelegate sharedBlog].managedObjectContext existingObjectWithID:authorId error:&coreDataError];
                if ( coreDataError ) {
                    [CRApp logErrorFormat:@"Unable to get managed object from id: %@", coreDataError.localizedDescription];
                }
            }
        }
    }

    if ( newAuthor == nil ) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"CWBlogAuthor" inManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
        newAuthor = [[CWBlogAuthor alloc] initWithEntity:entity insertIntoManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
    }

    newAuthor.user = author.user;
    newAuthor.displayName = author.displayName;
    newAuthor.email = author.email;
    return newAuthor;
}

@end
