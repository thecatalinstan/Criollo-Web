//
//  NSString+RegEx.m
//  
//
//  Created by Cătălin Stan on 30/08/16.
//
//

#import "NSString+RegEx.h"

@implementation NSString (RegEx)

- (NSString *)stringByReplacingPattern:(NSString *)pattern withTemplate:(NSString *)withTemplate error:(NSError *__autoreleasing  _Nullable *)error {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:error];
    return [regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:withTemplate];
}

@end
