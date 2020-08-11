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
    if (self == CWTwitterConfiguration.class) {
        [self updateDefaultConfiguration];
        [self monitorAndUpdateDefaultConfiguration];
    }
}

+ (void)monitorAndUpdateDefaultConfiguration {
    NSString *path = [CWAppDelegate.baseDirectory URLByAppendingPathComponent:@"twitter.json"].path;
    int handle;
    if (-1 == (handle = open(path.UTF8String, O_EVTONLY))) {
        [CRApp logErrorFormat:@"%@ Failed to monitor twitter configuration file. %@", [NSDate date], strerror(errno)];
        return;
    }
    
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, handle, DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE, dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0));
    dispatch_source_set_event_handler(source, ^{
        unsigned long flags = dispatch_source_get_data(source);
        if(flags & DISPATCH_VNODE_DELETE) {
            dispatch_source_cancel(source);
            return;
        }
        if(flags & DISPATCH_VNODE_WRITE) {
            [CRApp logFormat:@"%@ Twitter configuration file changed reloading.", [NSDate date]];
            [CWTwitterConfiguration updateDefaultConfiguration];
        }
    });
    
    dispatch_source_set_cancel_handler(source, ^(void) {
        close(handle);
    });
    
    dispatch_resume(source);
}

+ (void)updateDefaultConfiguration {
    NSError *error;

    NSData *data;
    if (!(data = [[NSData alloc] initWithContentsOfURL:[CWAppDelegate.baseDirectory URLByAppendingPathComponent:@"twitter.json"] options:NSDataReadingUncached error:&error])) {
        [CRApp logErrorFormat:@"%@ Error opening twitter configuration file. %@", [NSDate date], error.localizedDescription];
        return;
    }
    
    CWTwitterConfiguration *configuration;
    if (!(configuration = [[CWTwitterConfiguration alloc] initWithData:data error:&error])) {
        [CRApp logErrorFormat:@"%@ Error parsing twitter configuration file. %@", [NSDate date], error.localizedDescription];
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
