//
//  CWBlogTag.h
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//


#import "CWSchema.h"

@interface CWBlogTag : CWSchema

@property NSString * name;

@end

RLM_ARRAY_TYPE(CWBlogTag)
