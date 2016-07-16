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
    NSMutableCharacterSet* set = [[NSMutableCharacterSet alloc] init];
    [set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [set formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
    return [[self componentsSeparatedByCharactersInSet:set] componentsJoinedByString:@"-"].lowercaseString;
}

@end
