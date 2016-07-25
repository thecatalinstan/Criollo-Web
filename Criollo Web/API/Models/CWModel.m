//
//  CWModel.m
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWModel.h"
#import "CWAPIController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWModel ()

@end

NS_ASSUME_NONNULL_END

@implementation CWModel

- (NSString<Optional> *)path {
    return [NSString stringWithFormat:@"%@%@", CWAPIPath, self.publicPath];
}

@end
