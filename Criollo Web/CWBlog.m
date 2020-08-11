//
//  CWBlog.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import <MMMarkdown/MMMarkdown.h>
#import <STTwitter/STTwitter.h>

#import "CWBlog.h"
#import "CWBlogAuthor.h"
#import "CWBlogTag.h"
#import "CWUser.h"
#import "CWAppDelegate.h"
#import "CWTwitterConfiguration.h"

#import "NSString+URLUtils.h"
#import "NSString+RegEx.h"

static NSUInteger const CWExcerptLength = 400;

@implementation CWBlog

+ (RLMRealmConfiguration *) realmConfiguration {
    static RLMRealmConfiguration *realmConfig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *realmURL = [[CWAppDelegate.baseDirectory URLByAppendingPathComponent:self.className] URLByAppendingPathExtension:@"realm"];
        realmConfig = [RLMRealmConfiguration defaultConfiguration];
        realmConfig.fileURL = realmURL;
        realmConfig.readOnly = NO;
        realmConfig.deleteRealmIfMigrationNeeded = NO;
        realmConfig.objectClasses = @[
            CWBlogAuthor.class,
            CWBlogPost.class,
            CWBlogTag.class
        ];
        realmConfig.schemaVersion = 5;
        realmConfig.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
            // Nothing to do for migration
            if (oldSchemaVersion < 1) {
            }

            // Rename post.date to post.publishedDate
            if (oldSchemaVersion < 2) {
                [migration renamePropertyForClass:CWBlogPost.className oldName:@"date" newName:@"publishedDate"];
            }

            // Add the post.lastUpdatedDate property
            if (oldSchemaVersion < 3) {
                [migration enumerateObjects:CWBlogPost.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                    newObject[@"lastUpdatedDate"] = oldObject[@"publishedDate"];
                }];
            }

            // Add the twitter, imageURL and bio properties to the user
            if (oldSchemaVersion < 4) {
                [migration enumerateObjects:CWBlogAuthor.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                    newObject[@"twitter"] = @"";
                    newObject[@"imageURL"] = @"";
                    newObject[@"bio"] = @"";
                }];
            }

            // Add the locatoon to the user model
            if (oldSchemaVersion < 5) {
                [migration enumerateObjects:CWBlogAuthor.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                    newObject[@"location"] = @"";
                }];
            }
        };
    });
    return realmConfig;
}

+ (RLMRealm *)realm {
    NSError *error;
    RLMRealm *realm;
    if (!(realm = [RLMRealm realmWithConfiguration:CWBlog.realmConfiguration error:&error])) {
        [CRApp logErrorFormat:@"There was an error initializing the blog realm: %@", error];
        @throw [NSException exceptionWithName:NSGenericException reason:NSLocalizedString(@"Unable to get realm.",) userInfo:nil];
    }
    return realm;
}

- (BOOL)updateAuthors:(NSError * _Nullable __autoreleasing *)error {
    RLMRealm* realm = [CWBlog realm];
    
    for (CWUser *user in CWUser.allUsers) {
        [realm beginWriteTransaction];
        
        CWBlogAuthor *author = [CWBlogAuthor getByUser:user.username] ?: [CWBlogAuthor new];
        author.user = user.username;
        author.email = user.email;
        author.displayName = [[NSString stringWithFormat:@"%@ %@", user.firstName ?: @"", user.lastName ?: @""] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        author.handle = author.displayName.URLFriendlyHandle;
        author.twitter = [user.twitter hasPrefix:@"@"] ? user.twitter : [NSString stringWithFormat:@"@%@", user.twitter];
        
        [realm addOrUpdateObject:author];
        if (![realm commitWriteTransaction:error]) {
            return NO;
        }
    }

    return [self fetchTwitterInfo:error];
}

- (BOOL)fetchTwitterInfo:(NSError * _Nullable __autoreleasing *)error {
    if (!CWTwitterConfiguration.defaultConfiguration) {
        [CRApp logFormat:@"%@ Missing twitter login information. Extended user info will not be fetched from Twitter", [NSDate date]];
        return YES;
    }

    STTwitterAPI *twitter;
    if (!(twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:CWTwitterConfiguration.defaultConfiguration.key
                                                  consumerSecret:CWTwitterConfiguration.defaultConfiguration.secret
                                                      oauthToken:CWTwitterConfiguration.defaultConfiguration.token
                                                oauthTokenSecret:CWTwitterConfiguration.defaultConfiguration.tokenSecret])) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogTwitterError userInfo:@{NSLocalizedDescriptionKey: @"Failed to initialize the Twitter interface."}];
        }
        return NO;
    }
    
    RLMRealm* realm = [CWBlog realm];
    for (CWBlogAuthor* author in [CWBlogAuthor allObjectsInRealm:realm]) {
        if (author.twitter.length == 0) {
            continue;
        }

        // Get info from twitter
        [twitter getUserInformationFor:author.twitter successBlock:^(NSDictionary *user) {
            RLMRealm* realm = [CWBlog realm];
            [realm beginWriteTransaction];
            author.imageURL = user[@"profile_image_url_https"];
            author.bio = user[@"description"];
            author.location = user[@"location"];
            [realm commitWriteTransaction];
        } errorBlock:^(NSError *error){
            [CRApp logErrorFormat:@"%@ Failed to get Twitter information for %@. %@", [NSDate date], author.twitter, error.localizedDescription];
        }];
    }
    
    return YES;
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
    if ([markdownString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogEmptyPostContent userInfo:@{NSLocalizedDescriptionKey: @"Post was empty."}];
        }
        return nil;
    }
    
    return [MMMarkdown HTMLStringWithMarkdown:markdownString extensions:MMMarkdownExtensionsGitHubFlavored error:error];
}

+ (NSString *)excerptFromMarkdown:(NSString *)markdownString error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    if ([markdownString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogEmptyPostContent userInfo:@{NSLocalizedDescriptionKey: @"Post was empty."}];
        }
        return nil;
    }

    NSString * htmlString;
    if (!(htmlString = [CWBlog renderMarkdown:markdownString error:error])) {
        return nil;
    }

    return [CWBlog excerptFromHTML:htmlString error:error];
}

+ (NSString *)excerptFromHTML:(NSString *)htmlString error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    if ([htmlString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:CWBlogErrorDomain code:CWBlogEmptyPostContent userInfo:@{NSLocalizedDescriptionKey: @"Post was empty."}];
        }
        return nil;
    }

    NSString* contentMarkup = [NSString stringWithFormat:@"<div>%@</div>", htmlString];
    NSMutableString *excerpt = [[NSMutableString alloc] init];

    NSXMLElement* element;
    if (!(element = [[NSXMLElement alloc] initWithXMLString:contentMarkup error:error])) {
        return nil;
    }
    
    NSUInteger i = 0;
    for (NSXMLNode *obj in element.children) {
        if ([obj.name.lowercaseString isEqualToString:@"p"]) {
            [excerpt appendString:[obj.stringValue stringByReplacingOccurrencesOfString:@"\n" withString:@" "]];
            [excerpt appendString:@" "];
            i++;
        }
        
        if (excerpt.length > CWExcerptLength || i >= 3) {
            break;
        }
    }
    
    return excerpt;
}

+ (id)relatedPostsForPost:(CWBlogPost *)post {
    return [CWBlog relatedPostsForPost:post includeBlanks:NO];
}

+ (NSArray<CWBlogPost *>*)relatedPostsForPost:(CWBlogPost *)post includeBlanks:(BOOL)flag {
    // This is a very very very hacky solution
    NSSet* tags = [NSSet setWithArray:[post valueForKeyPath:@"tags.name"]];
    NSMutableArray* commonTagCounts = [NSMutableArray array];
    RLMResults* posts = [CWBlogPost allObjectsInRealm:[CWBlog realm]];
    for ( CWBlogPost *p in posts ) {
        if ( [p.uid isEqualToString:post.uid]) {
            continue;
        }
        NSSet* t = [NSSet setWithArray:[p valueForKeyPath:@"tags.name"]];
        NSMutableSet* commonTags = tags.mutableCopy;
        [commonTags intersectSet:t];

        [commonTagCounts addObject:@[p, commonTags]];
    }

    if ( !flag ) {
        [commonTagCounts filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSArray *  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            NSSet* commonTags = evaluatedObject[1];
            return commonTags.count > 0;
        }]];
    }

    [commonTagCounts sortUsingComparator:^NSComparisonResult(NSArray*  _Nonnull obj1, NSArray*  _Nonnull obj2) {
        NSSet* commonTags1 = obj1[1];
        NSSet* commonTags2 = obj2[1];
        NSComparisonResult result = [@(commonTags1.count) compare:@(commonTags2.count)];
        if ( result != NSOrderedSame ) {
            return result;
        }

        CWBlogPost* post1 = obj1[0];
        CWBlogPost* post2 = obj2[0];

        result = [post1.publishedDate compare:post2.publishedDate];
        return result;
    }];

    NSMutableArray* results = [NSMutableArray array];
    [commonTagCounts enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSArray*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CWBlogPost* post = obj[0];
        [results addObject:post];
    }];

    return results;
}

+ (NSString *)stringByReplacingTwitterTokens:(NSString *)text {
    return [[text stringByReplacingPattern:@"(@[\\w]+)" withTemplate:@"<a href=\"https://twitter.com/$1\">$1</a>" error:nil] stringByReplacingPattern:@"#([\\w]+)" withTemplate:@"<a href=\"https://twitter.com/hashtag/$1\">#$1</a>" error:nil];

}

@end

@implementation CWBlogDatePair

@end
