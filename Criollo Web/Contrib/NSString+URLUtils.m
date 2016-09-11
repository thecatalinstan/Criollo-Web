//
//  NSString+URLUtils.m
//  Criollo Web
//
//  Created by Cătălin Stan on 16/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "NSString+URLUtils.h"
#import "NSString+RegEx.h"

@implementation NSString (URLUtils)

- (NSString *)URLFriendlyHandle {
    NSString* romanized = [[NSString alloc] initWithData:[self dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] encoding:NSASCIIStringEncoding];
    return [[[romanized stringByReplacingPattern:@"[\\W]+" withTemplate:@" " error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingPattern:@"[\\s]+" withTemplate:@"-" error:nil].lowercaseString;
}

@end
