//
//  CWAPIResponse.m
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWAPIResponse.h"
#import "CWAPIError.h"

@implementation CWAPIResponse

- (instancetype)init {
    return [self initWithSucces:NO data:nil error:nil];
}

- (instancetype)initWithSucces:(BOOL)success data:(id)data error:(CWAPIError<Optional> *)error {
    self = [super init];
    if ( self != nil ) {
        self.success = success;
        self.data = data;
        self.error = error;
    }
    return self;
}

+ (instancetype)successResponseWithData:(id)data {
    return [[CWAPIResponse alloc] initWithSucces:YES data:data error:nil];
}

+ (instancetype)failureResponseWithError:(NSError *)error {
    return [[CWAPIResponse alloc] initWithSucces:NO data:nil error:CWAPIErrorFromNSError(error)];
}

@end
