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

    NSBundle* bundle = [NSBundle mainBundle];
    NSString* serverSpec = [NSString stringWithFormat:@"%@, v%@ build %@</h2>", bundle.bundleIdentifier, [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];

    // Session and identity block
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        // Server HTTP header
        [response setValue:serverSpec forHTTPHeaderField:@"Server"];

        // Session cookie
        if ( ! request.cookies[CWSessionCookie] ) {
            NSString* token = [NSUUID UUID].UUIDString;
            [response setCookie:CWSessionCookie value:token path:@"/" expires:nil domain:nil secure:NO];
        }

        completionHandler();
    }];

    // Homepage
    [self.server addController:[CWLandingPageViewController class] withNibName:@"CWLandingPageViewController" bundle:nil forPath:@"/"];


    // favicon.ico
    NSString* faviconPath = [bundle pathForResource:@"favicon" ofType:@"ico"];
    [self.server mountStaticFileAtPath:faviconPath forPath:@"/favicon.ico"];

    // Static resources folder
    NSString* publicResourcesFolder = [bundle.resourcePath stringByAppendingPathComponent:@"Public"];
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
