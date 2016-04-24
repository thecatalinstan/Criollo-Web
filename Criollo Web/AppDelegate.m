//
//  AppDelegate.m
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

@import CSSystemInfoHelper;
@import CSOddFormatters;

#import "AppDelegate.h"
#import "CWLandingPageViewController.h"

#define PortNumber          10781
#define LogConnections          0
#define LogRequests             0

NS_ASSUME_NONNULL_BEGIN

static NSDate *processStartTime;
static NSUInteger requestsServed;

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong) CRHTTPServer *server;

- (void)startServer;

@end
NS_ASSUME_NONNULL_END

@implementation AppDelegate {
    dispatch_queue_t backgroundQueue;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    processStartTime = [NSDate date];
    requestsServed = 0;
    backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    BOOL isFastCGI = [[NSUserDefaults standardUserDefaults] boolForKey:@"FastCGI"];
    Class serverClass = isFastCGI ? [CRFCGIServer class] : [CRHTTPServer class];
    self.server = [[serverClass alloc] initWithDelegate:self];

    NSBundle* bundle = [NSBundle mainBundle];
    NSString* serverSpec = [NSString stringWithFormat:@"%@, v%@ build %@", bundle.bundleIdentifier, [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];

    // Set some headers
    NSString* const ETagHeaderSpec = [NSString stringWithFormat:@"\"%@\"",[AppDelegate ETag]];
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        // Server HTTP header
        [response setValue:serverSpec forHTTPHeaderField:@"X-Criollo-Server"];

        // Session cookie
        if ( ! request.cookies[CWSessionCookie] ) {
            NSString* token = [NSUUID UUID].UUIDString;
            [response setCookie:CWSessionCookie value:token path:@"/" expires:nil domain:nil secure:YES];
        }

        // Cache
        if ( request.URL.pathExtension.length > 0 ) {
            [response setValue:ETagHeaderSpec forHTTPHeaderField:@"ETag"];
        }

        completionHandler();
    }];

    // Homepage
    CWLandingPageViewController* landingPageViewController = [[CWLandingPageViewController alloc] initWithNibName:nil bundle:nil];
    [self.server addBlock:landingPageViewController.routeBlock forPath:@"/"];
//    [self.server addController:[CWLandingPageViewController class] withNibName:@"CWLandingPageViewController" bundle:nil forPath:@"/"];

    // robot.txt
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* robotsString = @"User-agent: *\nAllow:\n";
        [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [response setValue:@(robotsString.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response send:robotsString];
        completionHandler();
    } forPath:@"/robots.txt"];

    // info
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* memoryInfo = [CSSystemInfoHelper sharedHelper].memoryUsageString;
        NSString* processName = [AppDelegate processName];
        NSString* processVersion = [AppDelegate bundleVersion];
        NSString* runningTime = [AppDelegate processRunningTime];
        NSString* unameSystemVersion = [CSSystemInfoHelper sharedHelper].systemVersionString;
        NSString * requestsServed = [AppDelegate requestsServed];
        NSString* processInfo;
        if ( memoryInfo ) {
            processInfo = [NSString stringWithFormat:@"%@ %@ using %@ of memory, running for %@ on %@. Served %@ requests.", processName, processVersion, memoryInfo, runningTime, unameSystemVersion, requestsServed];
        } else {
            processInfo = [NSString stringWithFormat:@"%@ %@, running for %@ on %@. Served %@ requests.", processName, processVersion, runningTime, unameSystemVersion, requestsServed];
        }
        [response sendString:processInfo];
    } forPath:@"/info"];


    // favicon.ico
    NSString* faviconPath = [bundle pathForResource:@"favicon" ofType:@"ico"];
    [self.server mountStaticFileAtPath:faviconPath forPath:@"/favicon.ico"];

    // Static resources folder
    NSString* publicResourcesFolder = [bundle.resourcePath stringByAppendingPathComponent:@"Public"];
    [self.server mountStaticDirectoryAtPath:publicResourcesFolder forPath:CWStaticDirPath options:CRStaticDirectoryServingOptionsCacheFiles];

    [self startServer];
}

- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender {
    static CRApplicationTerminateReply reply;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reply = CRTerminateLater;
        [self.server closeAllConnections:^{
            reply = CRTerminateNow;
        }];
    });
    return reply;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.server stopListening];
}


- (void)startServer {
    NSError *serverError;

    if ( [self.server startListening:&serverError portNumber:PortNumber] ) {

        // Get server ip address
        NSString* address = [CSSystemInfoHelper sharedHelper].IPAddress;

        // Set the base url. This is only for logging
        NSURL* baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d", address, PortNumber]];

        [CRApp logFormat:@"%@ Started HTTP server at %@", [NSDate date], baseURL.absoluteString];

        // Get the list of paths
        NSDictionary<NSString*, NSMutableArray<CRRoute*>*>* routes = [[self.server valueForKey:@"routes"] mutableCopy];
        NSMutableSet<NSURL*>* paths = [NSMutableSet set];

        [routes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<CRRoute *> * _Nonnull obj, BOOL * _Nonnull stop) {
            if ( [key hasSuffix:@"*"] ) {
                return;
            }
            NSString* path = [key substringFromIndex:[key rangeOfString:@"/"].location + 1];
            [paths addObject:[baseURL URLByAppendingPathComponent:path]];
        }];

        NSArray<NSURL*>* sortedPaths =[paths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"absoluteString" ascending:YES]]];
        [CRApp logFormat:@"Available paths are:"];
        [sortedPaths enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [CRApp logFormat:@" * %@", obj.absoluteString];
        }];

    } else {
        [CRApp logErrorFormat:@"%@ Failed to start HTTP server. %@", [NSDate date], serverError.localizedDescription];
        [CRApp terminate:nil];
    }
}

#if LogConnections
- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection {
    NSString* remoteAddress = connection.remoteAddress.copy;
    NSUInteger remotePort = connection.remotePort;
    dispatch_async( backgroundQueue, ^{
        [CRApp logFormat:@"Accepted connection from %@:%d", remoteAddress, remotePort];
    });
}

- (void)server:(CRServer *)server didCloseConnection:(CRConnection *)connection {
    NSString* remoteAddress = connection.remoteAddress.copy;
    NSUInteger remotePort = connection.remotePort;
    dispatch_async( backgroundQueue, ^{
        [CRApp logFormat:@"Disconnected %@:%d", remoteAddress, remotePort];
    });
}
#endif


- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request {
#if LogRequests
    NSString* contentLength = [request.response valueForHTTPHeaderField:@"Content-Length"];
    NSString* userAgent = request.env[@"HTTP_USER_AGENT"];
    NSString* remoteAddress = request.env[@"HTTP_X_FORWARDED_FOR"].length > 0 ? request.env[@"HTTP_X_FORWARDED_FOR"] : request.env[@"REMOTE_ADDR"];
    NSUInteger statusCode = request.response.statusCode;
    dispatch_async( backgroundQueue, ^{
        [CRApp logFormat:@"%@ %@ %@ - %lu %@ - %@", [NSDate date], remoteAddress, request, statusCode, contentLength ? : @"-", userAgent];
    });
#endif
    dispatch_async( backgroundQueue, ^{
        requestsServed++;
    });
}

#pragma mark - Utils

+ (NSString *)processName {
    static NSString* processName;
    if ( processName == nil ) {
        processName = [NSProcessInfo processInfo].processName;
    }
    return processName;
}

+ (NSString *)processRunningTime {
    return [CSTimeIntervalFormatter stringFromTimeInterval:processStartTime.timeIntervalSinceNow].lowercaseString;
}

+ (NSString *)requestsServed {
    return [NSString stringWithFormat:@"about %@", [CSLargeNumberFormatter stringFromNumber:@(requestsServed)]];
}

+ (NSString *)criolloVersion {
    static NSString* criolloVersion;
    if ( criolloVersion == nil ) {
        NSBundle *criolloBundle = [NSBundle bundleForClass:[CRServer class]];
        criolloVersion = [criolloBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if ( criolloVersion == nil ) {
            criolloVersion = CWCriolloVersion;
        }
    }
    return criolloVersion;
}

+ (NSString *)bundleVersion {
    static NSString* bundleVersion;
    if ( bundleVersion == nil ) {
        NSBundle *bundle = [NSBundle mainBundle];
        bundleVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }
    return bundleVersion;
}

+ (NSString *)ETag {
    static NSString* ETag;
    if ( ETag == nil ) {
        ETag = [[NSUUID UUID].UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""].lowercaseString;
    }
    return ETag;
}

@end
