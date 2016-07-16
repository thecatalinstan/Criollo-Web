//
//  CWModel.h
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CWModel : JSONModel

@property (nullable, nonatomic, strong) NSString<Optional> *uid;
@property (nullable, nonatomic, strong) NSString<Optional> *path;

@end

NS_ASSUME_NONNULL_END