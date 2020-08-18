//
//  CWAPIResponse.h
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@class CWAPIError;

NS_ASSUME_NONNULL_BEGIN
@interface CWAPIResponse : JSONModel

@property (nonatomic) BOOL success;
@property (nonatomic, strong, nullable) id<Optional> data;
@property (nonatomic, strong, nullable) CWAPIError<Optional> * error;

- (instancetype)initWithSucces:(BOOL)success data:(id _Nullable)data error:(CWAPIError<Optional> * _Nullable)error NS_DESIGNATED_INITIALIZER;

+ (instancetype)successResponseWithData:(id _Nullable)data;
+ (instancetype)failureResponseWithError:(NSError * _Nullable)error;

@end
NS_ASSUME_NONNULL_END
