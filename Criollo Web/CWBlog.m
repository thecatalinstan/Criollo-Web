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
#import "CWAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlog ()

@end

NS_ASSUME_NONNULL_END

@implementation CWBlogDatePair

@end

@implementation CWBlog

- (instancetype)init {
    return [self initWithBaseDirectory:[CWAppDelegate baseDirectory] error:nil];
}

- (instancetype)initWithBaseDirectory:(NSURL *)baseDirectory error:(NSError * __autoreleasing *)error {
    self = [super init];
    if ( self != nil ) {
        _baseDirectory = baseDirectory;

        // Realm
        NSURL *realmURL = [[_baseDirectory URLByAppendingPathComponent:self.className] URLByAppendingPathExtension:@"realm"];
        RLMRealmConfiguration* config = [RLMRealmConfiguration defaultConfiguration];
        config.fileURL = realmURL;
        config.readOnly = NO;
        config.deleteRealmIfMigrationNeeded = NO;

        _realm = [RLMRealm realmWithConfiguration:config error:error];
        if ( !_realm ) {
            return nil;
        }
    }
    return self;
}

- (BOOL)importUsersFromDefaults:(NSError * _Nullable __autoreleasing *)error {
    __block BOOL result = YES;

    [[CWUser allUsers] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, CWUser * _Nonnull user, BOOL * _Nonnull stop) {
//        *error = nil;
//        CWBlogAuthor *author = [CWBlogAuthor authorWithUsername:key];
//        if ( *error ) {
//            *stop = YES;
//            result = NO;
//            return;
//        }
//
//        if ( !author ) {
//            author = [[CWBlogAuthor alloc] initWithEntity:[NSEntityDescription entityForName:NSStringFromClass([CWBlogAuthor class]) inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext];
//        }
//
//        author.user = user.username;
//        author.email = user.email;
//        author.displayName = [[NSString stringWithFormat:@"%@ %@", user.firstName ? : @"", user.lastName ? : @""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//        author.handle = author.displayName.URLFriendlyHandle;
    }];

    *error = nil;
//    result = [self saveManagedObjectContext:error];

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
