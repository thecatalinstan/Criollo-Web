//
//  CWImageSize.m
//  Criollo Web
//
//  Created by Cătălin Stan on 11/08/2020.
//  Copyright © 2020 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

#import "CWImageSize.h"
#import "CWAppDelegate.h"

@implementation CWImageSize

static NSArray<CWImageSize *> *allSizes;

+ (void)initialize {
    if (self == CWImageSize.class) {
        [self updateSizes];
    }
}

+ (void)updateSizes {
    NSError *error;

    NSData *data;
    if (!(data = [[NSData alloc] initWithContentsOfURL:[NSBundle.mainBundle URLForResource:@"image-sizes" withExtension:@"json"] options:NSDataReadingUncached error:&error])) {
        [CRApp logErrorFormat:@"%@ Error opening image sizes file. %@", [NSDate date], error.localizedDescription];
        return;
    }

    NSArray<CWImageSize *> *sizes;
    if (!(sizes = [CWImageSize arrayOfModelsFromData:data error:&error])) {
        [CRApp logErrorFormat:@"%@ Error parsing image sizes file. %@", [NSDate date], error.localizedDescription];
        return;
    }

    @synchronized (allSizes) {
        allSizes = sizes;
    }
}

+ (NSArray<CWImageSize *> *)allSizes {
    @synchronized (allSizes) {
        return allSizes;
    }
}

@end

@implementation CWImageSizeRepresentation
@end
