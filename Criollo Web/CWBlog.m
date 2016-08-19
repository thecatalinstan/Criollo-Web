//
//  CWBlog.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import <MMMarkdown/MMMarkdown.h>

#import "CWBlog.h"
#import "CWBlogAuthor.h"
#import "CWBlogTag.h"
#import "CWBlogPost.h"
#import "CWUser.h"
#import "NSString+URLUtils.h"
#import "CWAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlog ()

@end

NS_ASSUME_NONNULL_END

@implementation CWBlogDatePair

@end

NS_ASSUME_NONNULL_BEGIN

@interface CWBlog()

@end

NS_ASSUME_NONNULL_END

@implementation CWBlog

+ (RLMRealmConfiguration *) realmConfiguration {
    static RLMRealmConfiguration *realmConfig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *realmURL = [[[CWAppDelegate baseDirectory] URLByAppendingPathComponent:self.className] URLByAppendingPathExtension:@"realm"];
        realmConfig = [RLMRealmConfiguration defaultConfiguration];
        realmConfig.fileURL = realmURL;
        realmConfig.readOnly = NO;
        realmConfig.deleteRealmIfMigrationNeeded = NO;
        realmConfig.objectClasses = @[[CWBlogAuthor class], [CWBlogPost class], [CWBlogTag class]];
    });
    return realmConfig;
}

+ (RLMRealm *)realm {
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:[CWBlog realmConfiguration] error:&error];
    if ( !realm ) {
        @throw [NSException exceptionWithName:NSGenericException reason:NSLocalizedString(@"Unable to get realm.",) userInfo:@{NSUnderlyingErrorKey: error}];
    }
    return realm;
}

- (BOOL)importUsersFromDefaults:(NSError * _Nullable __autoreleasing *)error {
    RLMRealm* realm = [CWBlog realm];
    [realm beginWriteTransaction];

    [[CWUser allUsers] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, CWUser * _Nonnull user, BOOL * _Nonnull stop) {
        CWBlogAuthor *author = [CWBlogAuthor getByUser:key];
        if ( !author ) {
            author = [[CWBlogAuthor alloc] init];
        }
        author.user = user.username;
        author.email = user.email;
        author.displayName = [[NSString stringWithFormat:@"%@ %@", user.firstName ? : @"", user.lastName ? : @""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        author.handle = author.displayName.URLFriendlyHandle;

        [realm addOrUpdateObject:author];
    }];

    return [realm commitWriteTransaction:error];
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

+ (CWBlogDatePair *)datePairArchivePeriod:(CWBlogArchivePeriod)period {
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

+ (CWBlogDatePair *)datePairWithYear:(NSUInteger)year month:(NSUInteger)month {
    return [CWBlog datePairArchivePeriod:[CWBlog parseYear:year month:month]];
}

+ (NSString *)renderMarkdown:(NSString *)markdownString error:(NSError *__autoreleasing  _Nullable *)error {
    if ( [markdownString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0 ) {
        return nil;
    }
    return [MMMarkdown HTMLStringWithMarkdown:markdownString extensions:MMMarkdownExtensionsGitHubFlavored error:error];
}


+ (NSString *)excerptFromMarkdown:(NSString *)markdownString error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    if ( [markdownString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0 ) {
        return nil;
    }

    *error = nil;
    NSString * htmlString = [CWBlog renderMarkdown:markdownString error:error];

    if ( htmlString == nil ) {
        return nil;
    }

    return [CWBlog excerptFromHTML:htmlString error:error];
}

+ (NSString *)excerptFromHTML:(NSString *)htmlString error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    if ( [htmlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0 ) {
        return nil;
    }

    NSString* contentMarkup = [NSString stringWithFormat:@"<div>%@</div>", htmlString];
    NSMutableString *excerpt = [[NSMutableString alloc] init];

    __block NSUInteger i = 0;
    NSError * xmlError;
    NSXMLElement* element = [[NSXMLElement alloc] initWithXMLString:contentMarkup error:&xmlError];
    [element.children enumerateObjectsUsingBlock:^(NSXMLNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( [obj.name.lowercaseString isEqualToString:@"p"] ) {
            [excerpt appendString:[obj.stringValue stringByReplacingOccurrencesOfString:@"\n" withString:@" "]];
            [excerpt appendString:@" "];
            i++;
        }

        if ( excerpt.length > 500 || i >= 3 ) {
            *stop = YES;
            return;
        }
    }];

    return excerpt;
}

@end
