//
//  CSLargeNumberFormatter.m
//  CSOddFormatters
//
//  Created by Cătălin Stan on 13/04/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CSLargeNumberFormatter.h"

NS_ASSUME_NONNULL_BEGIN
@interface CSLargeNumberFormatter ()

/**
 The internal shared instance of the formatter

 @return A pre-configured `CSLargeNumberFormatter` instance
 */
+ (instancetype)sharedFormatter;

/**
 The array of measurement units to use when formatting

 @return An array of units
 */
+ (NSArray<NSString *> *)units;

@end
NS_ASSUME_NONNULL_END

@implementation CSLargeNumberFormatter

static CSLargeNumberFormatter* sharedFormatter;

+ (void)initialize {
    sharedFormatter = [[CSLargeNumberFormatter alloc] init];
    sharedFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    sharedFormatter.maximumFractionDigits = 1;
}

+ (instancetype)sharedFormatter {
    return sharedFormatter;
}

+ (NSArray<NSString *> *)units {
    static NSArray<NSString *> * units;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        units = @[@"", @"K", @"M", @"B", @"trillion", @"quadrillion", @"quintillion", @"sextilion", @"septillion", @"octillion", @"nonillion", @"decillion", @"undecillion", @"duodecillion", @"tredecillion", @"quatttuor-decillion", @"quindecillion", @"sexdecillion", @"septen-decillion", @"octodecillion", @"novemdecillion", @"vigintillion"];
    });
    return units;
}

+ (NSString *)stringFromNumber:(NSNumber *)number {
    return [[CSLargeNumberFormatter sharedFormatter] stringFromNumber:number];
}

+ (NSNumber *)numberFromString:(NSString *)string {
    return [[CSLargeNumberFormatter sharedFormatter] numberFromString:string];
}

- (NSString *)stringFromNumber:(NSNumber *)number {
    NSString * string;
    if ( self.doNotUseHumanReadableUnits ) {
        string = [super stringFromNumber:number];
    } else {
        NSDecimalNumber * base = [NSDecimalNumber decimalNumberWithString:@"1000"];

        __block NSString *unit = @"";
        __block NSDecimalNumber* decimalNumber;
        if ( [number isKindOfClass:[NSDecimalNumber class]] ) {
            decimalNumber = (NSDecimalNumber *)number;
        } else {
            decimalNumber = [NSDecimalNumber decimalNumberWithString:number.stringValue];
        }

        if ( [decimalNumber compare:[base decimalNumberByRaisingToPower:[CSLargeNumberFormatter units].count]] != NSOrderedAscending ) {
            decimalNumber = [decimalNumber decimalNumberByDividingBy:[base decimalNumberByRaisingToPower:[CSLargeNumberFormatter units].count - 1]];
            unit = [CSLargeNumberFormatter units].lastObject;
        } else {
            [[CSLargeNumberFormatter units] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                unit = obj;
                if ( idx > 0 ) {
                    decimalNumber = [decimalNumber decimalNumberByDividingBy:base];
                }
//                NSLog(@" -- %@", decimalNumber);
                if ( [decimalNumber compare:base] == NSOrderedAscending ) {
                    *stop = YES;
                }
            }];
        }

        string = [[NSString stringWithFormat:@"%@ %@", [super stringFromNumber:decimalNumber], unit] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    return string;
}

- (NSNumber *)numberFromString:(NSString *)string {
    NSNumber * number;
    if ( self.doNotUseHumanReadableUnits ) {
        number = [super numberFromString:string];
    } else {
        string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        NSArray <NSString *> * components = [string componentsSeparatedByString:@" "];
        if ( components.count < 2 ) {
            number = [super numberFromString:string];
        } else {
            NSDecimalNumber * base = [NSDecimalNumber decimalNumberWithString:@"1000"];
            NSString * unit = components[1];
            NSUInteger powerOf1000 = unit.length == 0 ? 0 : MIN([[CSLargeNumberFormatter units] indexOfObject:unit], [CSLargeNumberFormatter units].count - 1);
            number = [[NSDecimalNumber decimalNumberWithString:components[0]] decimalNumberByMultiplyingBy:[base decimalNumberByRaisingToPower:powerOf1000]];
        }
    }
    return number;
}

@end
