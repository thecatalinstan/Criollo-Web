//
//  AppDelegate.m
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "AppDelegate.h"
#import "CWLandingPageViewController.h"

#define PortNumber          10781
#define LogConnections          0
#define LogRequests             0

@interface AppDelegate ()  <CRServerDelegate> {

}

@property (nonatomic, strong) CRHTTPServer *server;

- (void)startServer;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.server = [[CRHTTPServer alloc] initWithDelegate:self];

    // Homepage
    [self.server addController:[CWLandingPageViewController class] withNibName:@"CWLandingPageViewController" bundle:nil forPath:@"/"];

    // Static resources folder
    NSString* publicResourcesFolder = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"Public"];
    [self.server addStaticDirectoryAtPath:publicResourcesFolder forPath:@"/static" options:CRStaticDirectoryServingOptionsAutoIndex|CRStaticDirectoryServingOptionsCacheFiles];

    [self startServer];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.server stopListening];
}

- (void)startServer {
    NSError *serverError;
    if ( [self.server startListening:&serverError portNumber:PortNumber] ) {
        NSString *address = @"127.0.0.1";
        [CRApp logFormat:@"Started HTTP server at http://%@:%d", address, PortNumber];
    } else {
        [CRApp logErrorFormat:@"Failed to start HTTP server. %@", serverError.localizedDescription];
        [CRApp terminate:nil];
    }
}

@end
