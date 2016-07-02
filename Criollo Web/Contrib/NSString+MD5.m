//
//  NSString+MD5.m
//  Criollo Web
//
//  Created by Cătălin Stan on 02/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "NSString+MD5.h"

@implementation NSString (MD5)

- (NSString *)MD5Stirng {
    const char *cStr = self.UTF8String;
    unsigned char digest[16];
    CC_MD5( cStr, @(strlen(cStr)).intValue, digest );
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output.copy;
}

@end
