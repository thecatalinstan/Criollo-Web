//
//  CWGithubHelper.m
//  Criollo Web
//
//  Created by Cătălin Stan on 22/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import "CWGithubHelper.h"

@interface NSString (GithubURLS)
@property (nonatomic, readonly, copy) NSString *stringByRemovingOptionalsInURL;
@end

@implementation NSString (GithubURLS)

- (NSString *)stringByRemovingOptionalsInURL {
    NSUInteger idx;
    if (NSNotFound == (idx = [self rangeOfString:@"{"].location)) {
        return self;
    }
    
    return [self substringToIndex:idx];
}

@end

@implementation CWGithubModel
+ (JSONKeyMapper *)keyMapper {
    return JSONKeyMapper.mapperForSnakeCase;
}
@end

@implementation CWGithubRepo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONBlock:^NSString *(NSString *keyName) {
        if ([keyName isEqualToString:@"desc"]) {
            return @"description";
        } else {
            return JSONKeyMapper.mapperForSnakeCase.modelToJSONKeyBlock(keyName);
        }
    }];
}

@end

@implementation CWGithubUser
@end

@implementation CWGithubRelease
@end

static NSString * const baseURL = @"https://api.github.com/";
@implementation CWGithubHelper {
    NSURLSession * __strong session;
}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration];
    }
    return self;
}

- (void)dealloc {
    [session finishTasksAndInvalidate];
}

- (NSData *)request:(NSURL *)url error:(NSError *__autoreleasing *)error {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    dispatch_semaphore_t s = dispatch_semaphore_create(0);
    
    NSData * __block res;
    NSError * __block err;
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!data) {
            err = error;
            goto done;
        }
    
        res = data;
        
    done:
        dispatch_semaphore_signal(s);
    }];
    [task resume];
    
    dispatch_semaphore_wait(s, DISPATCH_TIME_FOREVER);
    
    if (error != NULL) {
        *error = err;
    }
    
    return res;
}

- (CWGithubRepo *)fetchRepo:(NSString *)fullName error:(NSError *__autoreleasing  _Nullable *)error {
    NSURL *url = [NSURL URLWithString:[[baseURL stringByAppendingPathComponent:@"repos"] stringByAppendingPathComponent:fullName]];
    
    NSData *data;
    if (!(data = [self request:url error:error])) {
        return nil;
    }
    
    return [[CWGithubRepo alloc] initWithData:data error:error];
}

- (CWGithubRelease *)fetchLatestReleaseForRepo:(CWGithubRepo *)repo error:(NSError *__autoreleasing  _Nullable *)error {
    NSURL *url = [NSURL URLWithString:repo.releasesUrl.stringByRemovingOptionalsInURL];
    
    NSData *data;
    if (!(data = [self request:url error:error])) {
        return nil;
    }
    
    NSArray<CWGithubRelease *> *releases;
    if (!(releases = [CWGithubRelease arrayOfModelsFromData:data error:error])) {
        return nil;
    }
    
    return releases.firstObject;
}

@end
