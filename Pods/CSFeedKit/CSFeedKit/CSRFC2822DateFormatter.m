//
//  CSRFC2822DateFormatter.m
//  CSFeedKit
//
//  Created by Cătălin Stan on 24/08/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CSRFC2822DateFormatter.h"

@implementation CSRFC2822DateFormatter

+ (instancetype)sharedInstance {
    static CSRFC2822DateFormatter* sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CSRFC2822DateFormatter alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self  = [super init];
    if ( self != nil ) {
        self.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z"; //RFC2822-Format
    }
    return self;
}

@end
