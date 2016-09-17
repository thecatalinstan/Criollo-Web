//
//  AppDelegate.m
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <CSSystemInfoHelper/CSSystemInfoHelper.h>
#import <CSOddFormatters/CSOddFormatters.h>
//#import <Fabric/Fabric.h>
//#import <Crashlytics/Crashlytics.h>

#import "CWAppDelegate.h"
#import "CWLandingPageViewController.h"
#import "CWBlogViewController.h"
#import "CWLoginPageViewController.h"
#import "CWBlog.h"
#import "CWBlogPost.h"
#import "CWBlogTag.h"
#import "CWBlogAuthor.h"
#import "CWAPIController.h"

#define DefaultPortNumber          10781
#define LogConnections          0
#define LogRequests             1

NS_ASSUME_NONNULL_BEGIN

static NSDate * processStartTime;
static NSUInteger requestsServed;
static NSURL * baseURL;
static NSUInteger portNumber;

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
//    [Fabric with:@[[Crashlytics class]]];
//    [CrashlyticsKit setUserIdentifier:[CSSystemInfoHelper sharedHelper].platformUUID];
//    [CrashlyticsKit setUserName:[CSSystemInfoHelper sharedHelper].systemInfo[CSSystemInfoNodenameKey]];
//#endif

    [self setupBaseDirectory];
    [self setupBlog];

    portNumber = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Port"] integerValue] ? : DefaultPortNumber;
    NSString * baseURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"BaseURL"];
    if ( !baseURLString ) {
        NSString* address = [CSSystemInfoHelper sharedHelper].IPAddress;
        baseURLString = [NSString stringWithFormat:@"http://%@:%lu", address ? : @"127.0.0.1", (unsigned long)portNumber];
    }
    baseURL = [NSURL URLWithString:baseURLString];

    BOOL isFastCGI = [[NSUserDefaults standardUserDefaults] boolForKey:@"FastCGI"];
    Class serverClass = isFastCGI ? [CRFCGIServer class] : [CRHTTPServer class];
    self.server = [[serverClass alloc] initWithDelegate:self];

    // Set some headers
    [self.server add:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        // Server HTTP header
        [response setValue:[CWAppDelegate serverSpecString] forHTTPHeaderField:@"X-Criollo-Server"];
        completionHandler();
    }];

    // Cache headers
    NSString* const ETagHeaderSpec = [NSString stringWithFormat:@"\"%@\"",[CWAppDelegate ETag]];
    [self.server add:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        if ( request.URL.pathExtension.length > 0 ) {
            [response setValue:ETagHeaderSpec forHTTPHeaderField:@"ETag"];
        }
        completionHandler();
    }];

    // API
    [self.server add:CWAPIPath controller:[CWAPIController class]];

    // Homepage
    [self.server add:CRPathSeparator viewController:[CWLandingPageViewController class] withNibName:nil bundle:nil recursive:NO method:CRHTTPMethodAll];

    // Blog
    [self.server add:CWBlogPath viewController:[CWBlogViewController class] withNibName:nil bundle:nil];

    // Login page
    [self.server add:CWLoginPath viewController:[CWLoginPageViewController class] withNibName:nil bundle:nil recursive:NO method:CRHTTPMethodAll];

    // Public resources folder
    NSString* publicResourcesFolder = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"Public"];
    [self.server mount:CWStaticDirPath directoryAtPath:publicResourcesFolder options:CRStaticDirectoryServingOptionsCacheFiles|CRStaticDirectoryServingOptionsAutoIndex];

    // sitemap.xml
    NSXMLElement *(^sitemapURLElementWithPath)(NSString * __Nonnull) = ^NSXMLElement * (NSString * path) { @autoreleasepool {
        NSXMLElement * urlElement = [NSXMLElement elementWithName:@"url"];
        [urlElement addChild:[NSXMLElement elementWithName:@"loc" stringValue:[NSURL URLWithString:path relativeToURL:baseURL].absoluteString]];
        return urlElement;
    }};
    [self.server get:@"/sitemap.xml" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        [response setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-type"];

        NSXMLElement *rootNode = [[NSXMLElement alloc] initWithName:@"urlset"];
        [rootNode addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.sitemaps.org/schemas/sitemap/0.9"]];
        [rootNode addNamespace:[NSXMLNode predefinedNamespaceForPrefix:@"xsi"]];
        [rootNode addAttribute:[NSXMLNode attributeWithName:@"xsi:schemaLocation" stringValue:@"http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"]];

        // root
        [rootNode addChild:sitemapURLElementWithPath(CRPathSeparator)];

        // blog
        [rootNode addChild:sitemapURLElementWithPath(CWBlogPath)];

        // posts
        RLMResults * posts = [CWBlogPost getObjectsWhere:@"published=true"];
        for ( CWBlogPost *post in posts ) {
            [rootNode addChild:sitemapURLElementWithPath(post.publicPath)];
        }

        // tags
        RLMResults * tags = [CWBlogTag allObjectsInRealm:[CWBlog realm]];
        for ( CWBlogTag *tag in tags ) {
            [rootNode addChild:sitemapURLElementWithPath(tag.publicPath)];
        }

        // authors
        RLMResults * authors = [CWBlogAuthor allObjectsInRealm:[CWBlog realm]];
        for ( CWBlogTag *author in authors ) {
            [rootNode addChild:sitemapURLElementWithPath(author.publicPath)];
        }

        NSXMLDocument *xml = [[NSXMLDocument alloc] initWithRootElement:rootNode];
        [response sendData:[xml XMLDataWithOptions:0]];
    }}];

    // robots.txt
    [self.server add:@"/robots.txt" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString* robotsString = @"User-agent: *\nAllow:\n";
        [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [response setValue:@(robotsString.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response send:robotsString];
    }}];

    // favicon.ico
    NSString* faviconPath = [[NSBundle mainBundle] pathForResource:@"favicon" ofType:@"ico"];
    [self.server mount:@"/favicon.ico" fileAtPath:faviconPath];

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
            reply = CRTerminateNow;
        }];
    });
    return reply;
}

- (void)startServer {

    NSError *serverError;
    if ( [self.server startListening:&serverError portNumber:portNumber] ) {
        [CRApp logFormat:@"%@ Started HTTP server at %@", [NSDate date], baseURL];

        // Get the list of paths
        NSArray<NSString *> * routePaths = [self.server valueForKeyPath:@"routes.path"];
        NSMutableArray<NSURL *> *paths = [NSMutableArray array];
        [routePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( [obj isKindOfClass:[NSNull class]] ) {
                return;
            }
            [paths addObject:[NSURL URLWithString:obj relativeToURL:baseURL]];
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
    _blog = [[CWBlog alloc] init];
    NSError *error;
    [self.blog importUsersFromDefaults:&error];
    if ( error ) {
        [CRApp logErrorFormat:@"%@ Failed to import users from defaults. %@", [NSDate date], error.localizedDescription];
        [CRApp terminate:nil];
    } else {
        [CRApp logFormat:@"%@ Successfully set up blog.", [NSDate date]];
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

+ (NSURL *)baseURL {
    return baseURL;
}

@end
