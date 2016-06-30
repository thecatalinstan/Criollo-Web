//
//  CWError.h
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <JSONModel/JSONModel.h>

#define CWAPIErrorDomain                    @"CWAPIErrorDomain"
#define CWAPIErrorLoginFailed               1001

@class CWAPIError;

NS_ASSUME_NONNULL_BEGIN

NSError * NSErrorFromCWAPIError(CWAPIError * apiError);
CWAPIError * CWAPIErrorFromNSError(NSError * error);

@interface CWAPIError : JSONModel

@property (nonatomic) NSInteger code;
@property (nonatomic, strong, nullable) NSString<Optional> * message;

- (instancetype)initWithCode:(NSUInteger)code message:(NSString * _Nullable)message NS_DESIGNATED_INITIALIZER;

+ (instancetype)APIErrorWithCode:(NSUInteger)code message:(NSString * _Nullable)message;

@end
NS_ASSUME_NONNULL_END