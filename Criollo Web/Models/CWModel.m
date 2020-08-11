//
//  CWModel.m
//  Criollo Web
//
//  Created by Cătălin Stan on 30/06/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWModel.h"
#import "CWAPIController.h"

@implementation CWModel

- (NSString<Optional> *)path {
    return [NSString stringWithFormat:@"%@%@", CWAPIPath, self.publicPath];
}

#pragma mark - CWSchemaProxy

- (CWSchema *)schemaObject {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ must be overriden in a subclass", NSStringFromSelector(_cmd)] userInfo:nil];
}

@end
