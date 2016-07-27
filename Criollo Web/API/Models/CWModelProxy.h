//
//  CWModelProxy.h
//  Criollo Web
//
//  Created by Cătălin Stan on 27/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

@class CWModel;

@protocol CWModelProxy <NSObject>

@required
- (nullable CWModel *)modelObject;

@end