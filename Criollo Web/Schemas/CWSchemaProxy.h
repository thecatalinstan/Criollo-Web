//
//  CWSchemaProxy.h
//  Criollo Web
//
//  Created by Cătălin Stan on 27/07/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

@class CWSchema;

@protocol CWSchemaProxy <NSObject>

@required
- (nullable CWSchema *)schemaObject;

@end