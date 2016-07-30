//
//  NSString+URLUtils.m
//  Criollo Web
//
//  Created by Cătălin Stan on 16/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "NSString+URLUtils.h"

@implementation NSString (URLUtils)

- (NSString *)URLFriendlyHandle {
    NSString* romanized = [[NSString alloc] initWithData:[self dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] encoding:NSASCIIStringEncoding];
    NSMutableCharacterSet* set = [[NSMutableCharacterSet alloc] init];
    [set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [set formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
    return [[romanized componentsSeparatedByCharactersInSet:set] componentsJoinedByString:@"-"].lowercaseString;
}

@end
