//
//  NSString+URLUtils.h
//  Criollo Web
//
//  Created by Cătălin Stan on 16/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URLUtils)

+ (nonnull NSString *)randomURLFriendlyHandle;

- (nonnull NSString *)URLFriendlyHandle;

@end
