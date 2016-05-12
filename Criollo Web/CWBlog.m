//
//  CWBlog.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlog.h"

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
@end
