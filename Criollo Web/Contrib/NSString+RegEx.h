//
//  NSString+RegEx.h
//  
//
//  Created by Cătălin Stan on 30/08/16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (RegEx)

- (nullable NSString *)stringByReplacingPattern:(NSString *)pattern withTemplate:(NSString *)withTemplate error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
