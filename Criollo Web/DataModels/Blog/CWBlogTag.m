//
//  CWBlogTag.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogTag.h"
#import "CWAPIBlogTag.h"
#import "CWAppDelegate.h"
#import "CWBlog.h"

@implementation CWBlogTag

- (NSString *)publicPath {
    return [NSString stringWithFormat:@"%@%@/%@", CWBlogPath, CWBlogTagPath, self.handle];
}

- (CWAPIBlogTag *)APIBlogTag {
    CWAPIBlogTag* apiBlogTag = [[CWAPIBlogTag alloc] init];
    apiBlogTag.uid = self.objectID.URIRepresentation.absoluteString;
    apiBlogTag.publicPath = self.publicPath;    
    apiBlogTag.name = self.name;
    apiBlogTag.handle = self.handle;
    return apiBlogTag;
}

+ (instancetype)tagWithHandle:(NSString *)handle {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CWBlogTag" inManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
    [fetchRequest setEntity:entity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"handle = %@", handle];
    [fetchRequest setPredicate:predicate];

    CWBlogTag * tag;
    NSArray *fetchedObjects = [[CWAppDelegate sharedBlog].managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects.count > 0) {
        tag = fetchedObjects.firstObject;
    }
    return tag;
}

+ (instancetype)blogTagFromAPIBlogTag:(CWAPIBlogTag *)tag {
    CWBlogTag* newTag;
    if ( tag.uid ) {
        NSURL* tagIdURIRepresentation = [NSURL URLWithString:tag.uid];
        if ( tagIdURIRepresentation ) {
            NSManagedObjectID* tagId = [[CWAppDelegate sharedBlog].managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:tagIdURIRepresentation];
            if ( tagId ) {
                NSError* coreDataError = nil;
                newTag = [[CWAppDelegate sharedBlog].managedObjectContext existingObjectWithID:tagId error:&coreDataError];
                if ( coreDataError ) {
                    [CRApp logErrorFormat:@"Unable to get managed object from id: %@", coreDataError.localizedDescription];
                }
            }
        }
    }

    if ( newTag == nil ) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"CWBlogTag" inManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
        newTag = [[CWBlogTag alloc] initWithEntity:entity insertIntoManagedObjectContext:[CWAppDelegate sharedBlog].managedObjectContext];
    }
    newTag.name = tag.name;
    newTag.handle = tag.handle;
    return newTag;
}

@end
