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

@interface CWAPIBlogImage : CWModel

@property (nullable, nonatomic, strong) NSString<Optional> *filename;
@property (nullable, nonatomic, strong) NSString<Optional> *mimeType;
@property (nonatomic) NSNumber<Optional> *filesize;
@property (nullable, nonatomic, strong) NSString<Optional> *handle;

@property (nullable, nonatomic, strong) NSArray<CWImageSizeRepresentation *><CWImageSizeRepresentation, Optional> *sizeRepresentations;

@end

NS_ASSUME_NONNULL_END
