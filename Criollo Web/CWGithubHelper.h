//
//  CWGithubHelper.h
//  Criollo Web
//
//  Created by Cătălin Stan on 22/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CWGithubModel : JSONModel
@end

@interface CWGithubUser : CWGithubModel

@property (nonatomic, strong) NSString *login;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *avatarUrl;

@end

@interface CWGithubRepo : CWGithubModel

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) CWGithubUser *owner;
@property (nonatomic, strong) NSString *htmlUrl;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *releasesUrl;
@property (nonatomic, strong) NSString *gitUrl;

@end

@interface CWGithubRelease : CWGithubModel

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *publishedAt;
@property (nonatomic, strong) NSString *tarballUrl;
@property (nonatomic, strong) NSString *zipballUrl;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSString *htmlUrl;

@end

@interface CWGithubHelper : NSObject

- (nullable CWGithubRepo *)fetchRepo:(NSString *)fullName error:(NSError *__autoreleasing *)error;
- (nullable CWGithubRelease *)fetchLatestReleaseForRepo:(CWGithubRepo *)repo error:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
