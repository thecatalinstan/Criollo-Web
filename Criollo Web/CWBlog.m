//
//  CWBlog.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <JSONModel/JSONModel.h>

#import "CWBlog.h"
#import "CWBlogAuthor.h"
#import "CWUser.h"
#import "NSString+URLUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlog ()

@end

NS_ASSUME_NONNULL_END

@implementation CWBlogDatePair

@end

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

- (BOOL)importUsersFromDefaults:(NSError * _Nullable __autoreleasing *)error {
    __block BOOL result = YES;
    [self.managedObjectContext performBlockAndWait:^{
        [[CWUser allUsers] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, CWUser * _Nonnull user, BOOL * _Nonnull stop) {
            *error = nil;
            CWBlogAuthor *author = [CWBlogAuthor authorWithUsername:key];
            if ( *error ) {
                *stop = YES;
                result = NO;
                return;
            }

            if ( !author ) {
                author = [[CWBlogAuthor alloc] initWithEntity:[NSEntityDescription entityForName:NSStringFromClass([CWBlogAuthor class]) inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext];
            }

            author.user = user.username;
            author.email = user.email;
            author.displayName = [[NSString stringWithFormat:@"%@ %@", user.firstName ? : @"", user.lastName ? : @""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            author.handle = author.displayName.URLFriendlyHandle;
        }];
        
        *error = nil;
        result = [self saveManagedObjectContext:error];
    }];
    return result;
}

- (BOOL)saveManagedObjectContext:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = YES;

    if (self.managedObjectContext.hasChanges) {
        NSError* mocSaveError;
        result = [self.managedObjectContext save:&mocSaveError];
        if ( !result ) {
            *error = mocSaveError;
        }
    }

    return result;
}

+ (NSString *)formattedDate:(NSDate *)date {
    static NSDateFormatter* dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.doesRelativeDateFormatting = YES;
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return [dateFormatter stringFromDate:date];
}

+ (NSString *)formattedTime:(NSDate *)date {
    static NSDateFormatter* dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterNoStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    return [dateFormatter stringFromDate:date];
}

+ (CWBlogArchivePeriod)parseYear:(NSUInteger)year month:(NSUInteger)month {
    if ( year == 0 ) {
        month = 0;
    }
    if ( month > 12 ) {
        month = 0;
    }
    return (CWBlogArchivePeriod){ year, month };
}

+ (CWBlogDatePair *)datePairWithYearMonth:(CWBlogArchivePeriod)period {
    NSUInteger startYear, endYear, startMonth, endMonth;
    startYear = period.year;
    if ( period.month == 0 ) {
        startMonth = 1;
        endYear = ++period.year;
        endMonth = 1;
    } else {
        startMonth = period.month;
        if ( period.month == 12 ) {
            endMonth = 1;
            endYear = ++period.year;
        } else {
            endMonth = ++period.month;
            endYear = period.year;
        }
    }

    CWBlogDatePair *datePair = [CWBlogDatePair new];
    datePair.startDate = [[NSCalendar currentCalendar] dateWithEra:1 year:startYear month:startMonth day:1 hour:0 minute:0 second:0 nanosecond:0];
    datePair.endDate = [[[NSCalendar currentCalendar] dateWithEra:1 year:endYear month:endMonth day:1 hour:0 minute:0 second:0 nanosecond:0] dateByAddingTimeInterval:-1];

    return datePair;
}

@end
