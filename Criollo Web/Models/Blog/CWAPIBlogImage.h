//
//  CWAPIBlogImage.h
//  Criollo Web
//
//  Created by Cătălin Stan on 11/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import "CWModel.h"
#import "CWImageSize.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CWImageSizeRepresentation
@end

@interface CWImageSizeRepresentation : JSONModel

@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;
@property (nullable, nonatomic, strong) NSString<Optional> *publicPath;

@end

@interface CWAPIBlogImage : CWModel

@property (nullable, nonatomic, strong) NSString *filename;
@property (nullable, nonatomic, strong) NSString *mimeType;
@property (nonatomic) NSInteger filesize;
@property (nullable, nonatomic, strong) NSString<Optional> *handle;

@property (nullable, nonatomic, strong) NSArray<CWImageSizeRepresentation *><CWImageSizeRepresentation, Optional> *sizeRepresentations;

@end

NS_ASSUME_NONNULL_END
