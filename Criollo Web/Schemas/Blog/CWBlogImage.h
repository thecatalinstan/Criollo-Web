//
//  CWBlogImage.h
//  Criollo Web
//
//  Created by Cătălin Stan on 11/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import "CWSchema.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogImage : CWSchema

@property NSString *filename;
@property NSString *mimeType;
@property NSUInteger filesize;

@end

NS_ASSUME_NONNULL_END
