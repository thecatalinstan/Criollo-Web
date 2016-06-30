//
//  CWError.m
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWAPIError.h"

NSError * NSErrorFromCWAPIError(CWAPIError * apiError) {
    return [NSError errorWithDomain:CWAPIErrorDomain code:apiError.code userInfo:@{NSLocalizedDescriptionKey: apiError.message ? : @"n/a"}];
}

CWAPIError * CWAPIErrorFromNSError(NSError * error) {
    return [CWAPIError APIErrorWithCode:error.code message:error.localizedDescription];
}

@implementation CWAPIError

- (instancetype)init {
    return [self initWithCode:0 message:nil];
}

- (instancetype)initWithCode:(NSUInteger)code message:(NSString *)message {
    self = [super init];
    if ( self != nil ) {
        self.code = code;
        self.message = message;
    }
    return self;
}

+ (instancetype)APIErrorWithCode:(NSUInteger)code message:(NSString *)message {
    return [[CWAPIError alloc] initWithCode:code message:message];
}

@end
