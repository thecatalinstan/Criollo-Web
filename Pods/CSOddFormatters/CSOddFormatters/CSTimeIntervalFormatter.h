//
//  CSTimeIntervalFormatter.h
//  CSOddFormatters
//
//  Created by Cătălin Stan on 12/04/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A subclass of `NSDateComponentsFormatter` that makes it a bit easier and more 
 reliable to format time intervals when dealing with a high volume of concurrent
 requests, such as in the context of a web-server.
 
 The preffered way of using it is through the class methods
 `stringFromTimeInterval:`, `stringFromDate:toDate:` and 
 `stringFromDateComponents:`, but it can also be used as any regular 
 `NSDateComponentsFormatter`.
 */
@interface CSTimeIntervalFormatter : NSDateComponentsFormatter

/**
 @name Getting a Formatted String from two NSDate Objects
 */

/**
 Returns the human-readable formatted value of the `NSTimeInterval` between 
 `endDate` and `startDate`. This efectively returns the value from an 
 `NSDateComponentsFormatter` set to use abbreviated units style, without time 
 left and approximation phrase.

 @param startDate The start date
 @param endDate   The end date

 @return A human-readable formatted value of the `NSTimeInterval` between 
 `endDate` and `startDate` or `nil` if an error has occured
*/
+ (nullable NSString *)stringFromDate:(NSDate *)startDate toDate:(NSDate *)endDate;

/**
 @name Getting a Formatted String from an NSTimeInterval
 */

/**
 Returns the human-readable formatted value of `timeInterval`. This efectively
 returns the value from an `NSDateComponentsFormatter` set to use abbreviated
 units style, without time left and approximation phrase.

 @param timeInterval The `NSTimeInterval` to be formatted

 @return A human-readable formatted value of `timeInterval` or `nil` if an error
 has occured
 */
+ (nullable NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval;

/**
 @name Getting a Formatted String from an NSDateComponents Object
 */

/*
 Returns the human-readable formatted value of `timeInterval`. This efectively
 returns the value from an `NSDateComponentsFormatter` set to use abbreviated
 units style, without time left and approximation phrase.

 @param components The `NSDateComponents` object to be formatted

 @return A human-readable formatted value of `timeInterval` or `nil` if an error
 has occured
 */
+ (nullable NSString *)stringFromDateComponents:(NSDateComponents *)components;

@end
NS_ASSUME_NONNULL_END