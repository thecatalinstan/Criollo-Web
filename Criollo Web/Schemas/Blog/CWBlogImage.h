//
//  CWBlogImage.h
//  Criollo Web
//
//  Created by Cătălin Stan on 11/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import "CWSchema.h"

@class CWImageSizeRepresentation, CRUploadedFile;

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogImage : CWSchema

@property NSString *filename;
@property NSString *mimeType;
@property NSNumber<RLMInt> *filesize;

@property (nullable, nonatomic, strong, readonly) NSArray<CWImageSizeRepresentation *> *sizeRepresentations;

- (BOOL)preocessUploadedFile:(CRUploadedFile *)file error:(NSError *__autoreloasing *)error;

@end

NS_ASSUME_NONNULL_END
