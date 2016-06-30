//
//  CWModel.m
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWModel.h"

NS_ASSUME_NONNULL_BEGIN
@interface CWModel ()

+(JSONKeyMapper *)mapperFromDashSeparatedToCamelCase;

@end
NS_ASSUME_NONNULL_END

@implementation CWModel

// Carbon copy of [JSONKeyMapper mapperFromUnderscoreCaseToCamelCase]
+(JSONKeyMapper *)mapperFromDashSeparatedToCamelCase {

    static JSONKeyMapper* mapperFromDashSeparatedToCamelCase;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        JSONModelKeyMapBlock toModel = ^ NSString * (NSString * keyName) {
            if ( [keyName rangeOfString:@"-"].location == NSNotFound) {
                return keyName;
            }

            //derive camel case out of underscore case
            NSString* camelCase = [keyName capitalizedString];
            camelCase = [camelCase stringByReplacingOccurrencesOfString:@"-" withString:@""];
            camelCase = [camelCase stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[camelCase substringToIndex:1].lowercaseString];

            return camelCase;
        };

        JSONModelKeyMapBlock toJSON = ^ NSString* (NSString* keyName) {

            NSMutableString* result = [NSMutableString stringWithString:keyName];
            NSRange upperCharRange = [result rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]];

            //handle upper case chars
            while ( upperCharRange.location!=NSNotFound) {

                NSString* lowerChar = [[result substringWithRange:upperCharRange] lowercaseString];
                [result replaceCharactersInRange:upperCharRange
                                      withString:[NSString stringWithFormat:@"-%@", lowerChar]];
                upperCharRange = [result rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]];
            }

            //handle numbers
            NSRange digitsRange = [result rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
            while ( digitsRange.location!=NSNotFound) {

                NSRange digitsRangeEnd = [result rangeOfString:@"\\D" options:NSRegularExpressionSearch range:NSMakeRange(digitsRange.location, result.length-digitsRange.location)];
                if (digitsRangeEnd.location == NSNotFound) {
                    //spands till the end of the key name
                    digitsRangeEnd = NSMakeRange(result.length, 1);
                }

                NSRange replaceRange = NSMakeRange(digitsRange.location, digitsRangeEnd.location - digitsRange.location);
                NSString* digits = [result substringWithRange:replaceRange];

                [result replaceCharactersInRange:replaceRange withString:[NSString stringWithFormat:@"-%@", digits]];
                digitsRange = [result rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet] options:kNilOptions range:NSMakeRange(digitsRangeEnd.location+1, result.length-digitsRangeEnd.location-1)];
            }

            return result;
        };

        mapperFromDashSeparatedToCamelCase = [[JSONKeyMapper alloc] initWithJSONToModelBlock:toModel modelToJSONBlock:toJSON];
    });

    return mapperFromDashSeparatedToCamelCase;

}

+ (void)initialize {
    [CWModel setGlobalKeyMapper:[CWModel mapperFromDashSeparatedToCamelCase]];
}

@end
