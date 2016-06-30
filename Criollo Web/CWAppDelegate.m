//
//  AppDelegate.m
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <CSSystemInfoHelper/CSSystemInfoHelper.h>
#import <CSOddFormatters/CSOddFormatters.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "CWAppDelegate.h"
#import "CWLandingPageViewController.h"
#import "CWBlogViewController.h"
#import "CWLoginPageViewController.h"
#import "CWBlog.h"
#import "CWAPIController.h"

#define PortNumber          10781
#define LogConnections          0
#define LogRequests             1

NS_ASSUME_NONNULL_BEGIN

static NSDate *processStartTime;
static NSUInteger requestsServed;

@interface CWAppDelegate () <CRServerDelegate>

@property (nonatomic, strong) CRHTTPServer *server;
@property (nonatomic, strong) CWBlog* blog;

- (void)startServer;
- (void)setupBaseDirectory;
- (void)setupBlog;

@end
NS_ASSUME_NONNULL_END

@implementation CWAppDelegate {
    dispatch_queue_t backgroundQueue;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    processStartTime = [NSDate date];
    requestsServed = 0;
    backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);

    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

//#ifndef DEBUG
//#endif

    [Fabric with:@[[Crashlytics class]]];
    [self setupBaseDirectory];
    [self setupBlog];

    BOOL isFastCGI = [[NSUserDefaults standardUserDefaults] boolForKey:@"FastCGI"];
    Class serverClass = isFastCGI ? [CRFCGIServer class] : [CRHTTPServer class];
    self.server = [[serverClass alloc] initWithDelegate:self];

    // Set some headers
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        // Server HTTP header
        [response setValue:[CWAppDelegate serverSpecString] forHTTPHeaderField:@"X-Criollo-Server"];

        // Session cookie
        if ( ! request.cookies[CWSessionCookie] ) {
            NSString* token = [NSUUID UUID].UUIDString;
            [response setCookie:CWSessionCookie value:token path:@"/" expires:nil domain:nil secure:YES];
        }

        completionHandler();
    }];

    // Info
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* memoryInfo = [CSSystemInfoHelper sharedHelper].memoryUsageString;
        NSString* processName = [CWAppDelegate processName];
        NSString* processVersion = [CWAppDelegate bundleVersion];
        NSString* runningTime = [CWAppDelegate processRunningTime];
        NSString* unameSystemVersion = [CSSystemInfoHelper sharedHelper].systemVersionString;
        NSString * requestsServed = [CWAppDelegate requestsServed];
        NSString* processInfo;
        if ( memoryInfo ) {
            processInfo = [NSString stringWithFormat:@"%@ %@ using %@ of memory, running for %@ on %@. Served %@ requests.", processName, processVersion, memoryInfo, runningTime, unameSystemVersion, requestsServed];
        } else {
            processInfo = [NSString stringWithFormat:@"%@ %@, running for %@ on %@. Served %@ requests.", processName, processVersion, runningTime, unameSystemVersion, requestsServed];
        }
        [response sendString:processInfo];
    } forPath:@"/info"];

    // API

    [self.server addBlock:[CWAPIController sharedController].routeBlock forPath:@"/api" HTTPMethod:CRHTTPMethodAll recursive:YES];


    // Cache headers
    NSString* const ETagHeaderSpec = [NSString stringWithFormat:@"\"%@\"",[CWAppDelegate ETag]];
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        // Cache
        if ( request.URL.pathExtension.length > 0 ) {
            [response setValue:ETagHeaderSpec forHTTPHeaderField:@"ETag"];
        }
        completionHandler();
    }];

    // Homepage
    [self.server addController:[CWLandingPageViewController class] withNibName:@"CWLandingPageViewController" bundle:nil forPath:@"/"];

    // Blog
    [self.server addController:[CWBlogViewController class] withNibName:@"CWBlogViewController" bundle:nil forPath:@"/blog"];

    // Login page
    [self.server addController:[CWLoginPageViewController class] withNibName:@"CWLoginPageViewController" bundle:nil forPath:@"/login"];

    // robot.txt
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* robotsString = @"User-agent: *\nAllow:\n";
        [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [response setValue:@(robotsString.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response send:robotsString];
        completionHandler();
    } forPath:@"/robots.txt"];

    // favicon.ico
    NSString* faviconPath = [[NSBundle mainBundle] pathForResource:@"favicon" ofType:@"ico"];
    [self.server mountStaticFileAtPath:faviconPath forPath:@"/favicon.ico"];

    // Static resources folder
    NSString* publicResourcesFolder = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"Public"];
    [self.server mountStaticDirectoryAtPath:publicResourcesFolder forPath:CWStaticDirPath options:CRStaticDirectoryServingOptionsCacheFiles];

    [self startServer];
}

- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender {
    static CRApplicationTerminateReply reply;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Delay the shutdown for a bit
        reply = CRTerminateLater;

        // Close server connections
        [CRApp logFormat:@"%@ Closing server connections.", [NSDate date]];
        [self.server closeAllConnections:^{

            // Stop the server and close the socket cleanly
            [CRApp logFormat:@"%@ Sutting down server.", [NSDate date]];
            [self.server stopListening];

            // Save the blog managed context
            [CRApp logFormat:@"%@ Saving blog MOC changes.", [NSDate date]];
            [self.blog.managedObjectContext performBlock:^{
                NSError* error = nil;
                if ( ![self.blog saveManagedObjectContext:&error] )  {
                    [CRApp logErrorFormat:@"%@ Unable to save the blog MOC. %@. Trying again in 5 seconds.", [NSDate date], error.localizedDescription];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                        [self.blog.managedObjectContext performBlock:^{
                            NSError* error = nil;
                            if ( ![self.blog saveManagedObjectContext:&error] ) {
                                [CRApp logErrorFormat:@"%@ Unable to save the blog context. %@. No firther attepts to save will be made. Some data might have been lost.", [NSDate date], error.localizedDescription];
                            } else {
                                [CRApp logFormat:@"%@ Successfully saved blog MOC.", [NSDate date]];
                            }
                            reply = CRTerminateNow;
                        }];
                    });
                } else {
                    reply = CRTerminateNow;
                }
            }];
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

- (void)setupBaseDirectory {
    NSError* error = nil;
    BOOL shouldFail = NO;
    NSURL* baseDirectory = [CWAppDelegate baseDirectory];
    NSString* failureReason = @"There was an error creating or loading the application's saved data.";

    NSDictionary *properties = [baseDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason = @"Expected a folder to store application data, found a file.";
            shouldFail = YES;
        }
    } else if (error.code == NSFileReadNoSuchFileError) {
        error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:baseDirectory.path withIntermediateDirectories:YES attributes:nil error:&error];
    }

    if (shouldFail || error) {
        if ( error ) {
            failureReason = error.localizedDescription;
        }
        [CRApp logErrorFormat:@"%@ Failed to set up application directory %@. %@", [NSDate date], baseDirectory, failureReason];
        [CRApp terminate:nil];
    } else {
        [CRApp logFormat:@"%@ Successfully set up application directory %@.", [NSDate date], baseDirectory.path];
    }
}

- (void)setupBlog {
    NSError* error;
    _blog = [[CWBlog alloc] initWithBaseDirectory:[CWAppDelegate baseDirectory] error:&error];
    if (error) {
        [CRApp logErrorFormat:@"%@ Failed to set up the blog. %@", [NSDate date], error.localizedDescription];
        [CRApp terminate:nil];
    } else {
        error = nil;
        [self.blog importUsersFromDefaults:&error];
        if ( error ) {
            [CRApp logErrorFormat:@"%@ Failed to import users from defaults. %@", [NSDate date], error.localizedDescription];
            [CRApp terminate:nil];
        } else {
            [CRApp logFormat:@"%@ Successfully set up blog.", [NSDate date]];
        }
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

+ (NSString *)serverSpecString {
    static NSString* serverSpecString;
    if ( serverSpecString == nil ) {
        NSBundle* bundle = [NSBundle mainBundle];
        serverSpecString = [NSString stringWithFormat:@"%@, v%@ build %@", bundle.bundleIdentifier, [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
    }
    return serverSpecString;
}

+ (NSString *)processName {
    static NSString* processName;
    if ( processName == nil ) {
        processName = [NSProcessInfo processInfo].processName;
    }
    return processName;
}

+ (NSString *)processRunningTime {
    return [CSTimeIntervalFormatter stringFromTimeInterval:-processStartTime.timeIntervalSinceNow].lowercaseString;
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

+ (NSURL *)baseDirectory {
    static NSURL* baseDirectory;
    if ( baseDirectory == nil ) {
        baseDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].lastObject;
        baseDirectory = [baseDirectory URLByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleNameKey]];
    }
    return baseDirectory;
}

+ (CWBlog *)sharedBlog {
    return ((CWAppDelegate*)[CRApp delegate]).blog;
}

@end
