//
//  CWTwitterConfig.h
//  Criollo Web
//
//  Created by Catalin Stan on 11/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import "CWModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWTwitterConfiguration : CWModel

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *secret;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *tokenSecret;

@property (class, nonatomic, strong, readonly) CWTwitterConfig *default

@end

NS_ASSUME_NONNULL_END
