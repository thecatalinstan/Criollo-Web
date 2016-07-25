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
    return [NSString stringWithFormat:@"%@%@/%@", CWBlogPath, CWBlogAuthorPath, self.handle];
}

- (CWAPIBlogAuthor *)APIBlogAuthor {
    CWAPIBlogAuthor *apiBlogAuthor = [[CWAPIBlogAuthor alloc] init];
    apiBlogAuthor.uid = self.objectID.URIRepresentation.absoluteString;
    apiBlogAuthor.publicPath = self.publicPath;
    apiBlogAuthor.displayName = self.displayName;
    apiBlogAuthor.email = self.email;
    apiBlogAuthor.user = self.user;
    apiBlogAuthor.handle = self.handle;
    return apiBlogAuthor;
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
    newAuthor.handle = author.handle;
    return newAuthor;
}

+ (instancetype)authorWithHandle:(NSString *)handle {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CWBlogAuthor" inManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
    [fetchRequest setEntity:entity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"handle = %@", handle];
    [fetchRequest setPredicate:predicate];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

    CWBlogAuthor * author;
    NSArray *fetchedObjects = [[CWAppDelegate sharedBlog].managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects.count > 0) {
        author = fetchedObjects.firstObject;
    }
    return author;
}

+ (instancetype)authorWithUsername:(NSString *)username {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CWBlogAuthor" inManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
    [fetchRequest setEntity:entity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user.username = %@", username];
    [fetchRequest setPredicate:predicate];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

    CWBlogAuthor * author;
    NSArray *fetchedObjects = [[CWAppDelegate sharedBlog].managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects.count > 0) {
        author = fetchedObjects.firstObject;
    }
    return author;
}

@end
