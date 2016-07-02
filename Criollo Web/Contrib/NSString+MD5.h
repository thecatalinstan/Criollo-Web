//
//  NSString+MD5.h
//  Criollo Web
//
//  Created by Cătălin Stan on 02/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (MD5)

- (NSString *)MD5Stirng;

@end

NS_ASSUME_NONNULL_END