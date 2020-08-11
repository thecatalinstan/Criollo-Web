//
//  CWTwitterConfiguration.m
//  Criollo Web
//
//  Created by Catalin Stan on 11/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

#import "CWTwitterConfiguration.h"
#import "CWAppDelegate.h"

@implementation CWTwitterConfiguration

static CWTwitterConfiguration *defaultConfiguration;

+ (void)initialize {
    if (self != CWTwitterConfiguration.class) {
        return;
    }
    
    [self updateDefaultConfiguration];
}

+ (void)updateDefaultConfiguration {
    NSError *error;

    NSData *data;
    if (!(data = [[NSData alloc] initWithContentsOfURL:[CWAppDelegate.baseDirectory URLByAppendingPathComponent:@"twitter.json"] options:NSDataReadingUncached error:&error])) {
        [CRApp logErrorFormat:@"%@ Error opening twitter configuration file. %@", [NSDate date], error];
        return;
    }
    
    CWTwitterConfiguration *configuration;
    if (!(configuration = [[CWTwitterConfiguration alloc] initWithData:data error:&error])) {
        [CRApp logErrorFormat:@"%@ Error parsing twitter configuration file. %@", [NSDate date], error];
        return;
    }
    
    @synchronized (defaultConfiguration) {
        defaultConfiguration = configuration;
    }
}

+ (CWTwitterConfiguration *)defaultConfiguration {
    @synchronized (defaultConfiguration) {
        return defaultConfiguration;
    }
}

@end
