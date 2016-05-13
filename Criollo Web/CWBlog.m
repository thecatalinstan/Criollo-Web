//
//  CWBlog.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlog.h"
#import "CWBlogAuthor.h"
#import "CWAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlog ()


@end

NS_ASSUME_NONNULL_END

@implementation CWBlog

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (instancetype)initWithBaseDirectory:(NSURL *)baseDirectory error:(NSError * __autoreleasing *)error {
    self = [super init];
    if ( self != nil ) {
        _baseDirectory = baseDirectory;

        // Model
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.className withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

        // Store
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];

        NSURL *storeURL = [[self.baseDirectory URLByAppendingPathComponent:self.className] URLByAppendingPathExtension:@"sqlite"];
        NSDictionary *storeOptions = @{
                                       NSSQLiteAnalyzeOption: @YES,
                                       NSSQLiteManualVacuumOption: @YES,
                                       NSMigratePersistentStoresAutomaticallyOption: @YES,
                                       NSInferMappingModelAutomaticallyOption: @YES
                                       };
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:storeOptions error:error]) {
            _persistentStoreCoordinator = nil;
            return nil;
        }

        // Context
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    }
    return self;
}

- (void)importUsersFromDefaults:(NSError * _Nullable __autoreleasing *)error {
    [[NSUserDefaults standardUserDefaults ] synchronize];
    NSDictionary * defaultsUsers = [[NSUserDefaults standardUserDefaults] dictionaryForKey:CWDefaultsUsersKey];
    if ( !defaultsUsers ) {
        return;
    }

    [self.managedObjectContext performBlockAndWait:^{
        [defaultsUsers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            NSError * fetchError = nil;
            CWBlogAuthor *author = [CWBlogAuthor fetchAuthorForUsername:key inManagedObjectContext:self.managedObjectContext error:&fetchError];
            if ( fetchError ) {
                *stop = YES;
            } else if ( !author ) {
                author = [[CWBlogAuthor alloc] initWithEntity:[NSEntityDescription entityForName:NSStringFromClass([CWBlogAuthor class]) inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext];
                author.user = key;
            };
        }];
        *error = nil;
        [self saveManagedObjectContext:error];
    }];
}

- (BOOL)saveManagedObjectContext:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = YES;

    if (self.managedObjectContext.hasChanges) {
        *error = nil;
        result = [self.managedObjectContext save:error];
    }

    return result;
}


@end
