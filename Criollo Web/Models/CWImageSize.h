//
//  CWImageSize.h
//  Criollo Web
//
//  Created by Cătălin Stan on 11/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@class CRRequest;

NS_ASSUME_NONNULL_BEGIN

@interface CWImageSize : JSONModel

@property (nonatomic, strong) NSString *label;
@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;

@property (class, nonatomic, strong, readonly) NSArray<CWImageSize *> *availableSizes;

@end

typedef NS_ENUM(NSUInteger, CWImageSizeLabel) {
    CWImageSizeLabelThumb          = 0,
    CWImageSizeLabelMedium         = 1,
    CWImageSizeLabelLarge          = 2,
    CWImageSizeLabelShareImage     = 3
};

@protocol CWImageSizeRepresentation
@end

@interface CWImageSizeRepresentation : JSONModel

@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;
@property (nullable, nonatomic, strong) NSString<Optional> *publicPath;

- (NSString *)permalinkForRequest:(CRRequest *)request;

@end

NS_ASSUME_NONNULL_END
