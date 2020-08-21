//
//  NSString+URLUtils.m
//  Criollo Web
//
//  Created by Cătălin Stan on 16/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "NSString+URLUtils.h"
#import "NSString+RegEx.h"

static char * const randomURLFriendlyHandlePool = "abcdefghijklmnoprstuvwxyzABCDEFGHIJKLMNOPRSTUVWXYZ0123456789";

@implementation NSString (URLUtils)

+ (NSString *)randomURLFriendlyHandle {
    return [self randomURLFriendlyHandle:16 pool:randomURLFriendlyHandlePool size:strlen(randomURLFriendlyHandlePool)];
}

+ (NSString *)randomURLFriendlyHandle:(NSUInteger)length pool:(char *)pool size:(unsigned long)size {
    length = MIN(length, size);
    char handle[length + 1];
    for (NSUInteger i = 0; i < length; i++ ) {
        handle[i] = pool[arc4random_uniform((uint32_t)size)];
    }
    handle[length] = '\0';
    return @(handle);
}

- (NSString *)URLFriendlyHandle {
    NSString* romanized = [[NSString alloc] initWithData:[self dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] encoding:NSASCIIStringEncoding];
    return [[[romanized stringByReplacingPattern:@"[\\W]+" withTemplate:@" " error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingPattern:@"[\\s]+" withTemplate:@"-" error:nil].lowercaseString;
}

@end
