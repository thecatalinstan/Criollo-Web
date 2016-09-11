//
//  main.m
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>
#import "CWAppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        return CRApplicationMain(argc, argv, [CWAppDelegate new]);
    }
}
