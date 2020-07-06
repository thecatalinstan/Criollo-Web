//
//  CSLargeNumberFormatter.h
//  CSOddFormatters
//
//  Created by Cătălin Stan on 13/04/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A subclass of `NSNumberFormatter` that adds the ability to shorten large numbers
 to a more human-readable number format. Instead of `1450000` it will output
 `1.4 M` and so on.

 It also makes it a bit easier and more reliable to format when dealing with a 
 high volume of concurrent requests, by using a shared instance.
 
 The preffered way of using it is through the class methods `stringFromNumber:` 
 and `numberFromString:`, but it can also be used as any regular 
 `NSNumberFormatter`.
 */
@interface CSLargeNumberFormatter : NSNumberFormatter

/**
 @name Getting a String from an NSNumber
 */

/**
 Returns a string containing the formatted value of the provided number object.

 @param number An `NSNumber` object that is parsed to create the returned string
 object.

 @return A string containing the formatted value of number using the receiver’s 
 current settings or `nil` if an error has occured
 */
+ (nullable NSString *)stringFromNumber:(NSNumber *)number;

/**
 @name Getting an NSNumber from a Formatted Dtring
 */

/**
 Returns an `NSNumber` object created by parsing a given string.

 @param string An `NSString` object that is parsed to generate the returned
 number object.

 @return An NSNumber object created by parsing string using the receiver’s format
 of `nil` if there are no numbers in the passed string.
 */
+ (nullable NSNumber *)numberFromString:(NSString *)string;

/**
 @name Formatting the Output String
 */

/**
 Determines wether to use the fancy units replacement or to revert to normal 
 `NSNumberFormatter` behaviour. Default is `NO`.
 */
@property (nonatomic, assign) BOOL doNotUseHumanReadableUnits;

@end
NS_ASSUME_NONNULL_END