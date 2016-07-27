//
//  CWModel.h
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "CWSchemaProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWModel : JSONModel<CWSchemaProxy>

@property (nullable, nonatomic, strong) NSString<Optional> *uid;
@property (nullable, nonatomic, strong, readonly) NSString<Optional> *path;
@property (nullable, nonatomic, strong) NSString<Optional> *publicPath;

@end

NS_ASSUME_NONNULL_END