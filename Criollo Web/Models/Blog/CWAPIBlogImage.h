//
//  CWAPIBlogImage.h
//  Criollo Web
//
//  Created by Cătălin Stan on 11/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import "CWModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWAPIBlogImage : CWModel

@property (nullable, nonatomic, strong) NSString *filename;
@property (nullable, nonatomic, strong) NSString *mimeType;
@property (nonatomic) NSInteger filesize;
@property (nullable, nonatomic, strong) NSString<Optional> *handle;

@end

NS_ASSUME_NONNULL_END
