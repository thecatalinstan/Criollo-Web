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
#define LogRequests             1

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


    // favicon.ico
    NSString* faviconPath = [[NSBundle mainBundle] pathForResource:@"favicon" ofType:@"ico"];
    [self.server mountStaticFileAtPath:faviconPath forPath:@"/favicon.ico"];

    // Static resources folder
    NSString* publicResourcesFolder = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"Public"];
    [self.server mountStaticDirectoryAtPath:publicResourcesFolder forPath:CWStaticDirPath options:CRStaticDirectoryServingOptionsAutoIndex|CRStaticDirectoryServingOptionsCacheFiles|CRStaticDirectoryServingOptionsAutoIndex];

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

#if LogConnections
- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection {
    [CRApp logFormat:@" * Accepted connection from %@:%d", connection.remoteAddress, connection.remotePort];
}

- (void)server:(CRServer *)server didCloseConnection:(CRConnection *)connection {
    [CRApp logFormat:@" * Disconnected %@:%d", connection.remoteAddress, connection.remotePort];
}
#endif

#if LogRequests
- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request {
    NSString* contentLength = [request.response valueForHTTPHeaderField:@"Content-Length"];
    NSString* userAgent = request.env[@"HTTP_USER_AGENT"];
    NSString* remoteAddress = request.connection.remoteAddress;
    NSUInteger statusCode = request.response.statusCode;
    [CRApp logFormat:@"%@ %@ - %lu %@ - %@", remoteAddress, request, statusCode, contentLength ? : @"-", userAgent];
}
#endif

@end
