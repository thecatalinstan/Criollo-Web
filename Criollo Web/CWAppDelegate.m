//
//  AppDelegate.m
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <CSSystemInfoHelper/CSSystemInfoHelper.h>
#import <CSOddFormatters/CSOddFormatters.h>

#import "CWAppDelegate.h"
#import "CWLandingPageViewController.h"
#import "CWBlogViewController.h"
#import "CWLoginPageViewController.h"
#import "CWBlog.h"
#import "CWAPIController.h"
#import "CWSitemapController.h"
#import "CWGithubHelper.h"

NSNotificationName const CWRoutesChangedNotificationName = @"CWRoutesChangedNotification";

NSString * const CWStaticDirPath = @"/static";
NSString * const CWLoginPath = @"/login";

NSUInteger const DefaultPortNumber = 10781;

#define LogConnections             0
#define LogRequests                1

static NSDate *processStartTime;
static NSUInteger requestsServed;
static NSURL *baseURL;
static NSUInteger portNumber;
static dispatch_queue_t backgroundQueue;
static NSString *serverSpecString;
static NSString *processName;
static NSString *bundleVersion;
static NSURL *baseDirectory;
static NSString *ETag;
static CWGithubRepo *githubRepo;
static CWGithubRelease *githubRelease;
static CWGithubRepo *webGithubRepo;


NS_ASSUME_NONNULL_BEGIN

@interface CWAppDelegate () <CRServerDelegate>

@property (nonatomic, strong) CRServer *server;
@property (nonatomic, strong) CWBlog* blog;

@end

NS_ASSUME_NONNULL_END

@implementation CWAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [NSUserDefaults.standardUserDefaults registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupBaseDirectory];
    [self setupBlog];
    
    [self setupGithubPolling];

    // Setup server
    BOOL isFastCGI = [NSUserDefaults.standardUserDefaults boolForKey:@"FastCGI"];
    Class serverClass = isFastCGI ? [CRFCGIServer class] : [CRHTTPServer class];
    self.server = [[serverClass alloc] initWithDelegate:self];

    // Setup HTTPS
    if (!isFastCGI && [NSUserDefaults.standardUserDefaults boolForKey:@"Secure"]) {
        [self setupHTTPS];
    }

    portNumber = [[NSUserDefaults.standardUserDefaults objectForKey:@"Port"] integerValue] ? : DefaultPortNumber;
    NSString * baseURLString = [NSUserDefaults.standardUserDefaults objectForKey:@"BaseURL"];
    if ( !baseURLString ) {
        NSString* address = [CSSystemInfoHelper sharedHelper].IPAddress;
        baseURLString = [NSString stringWithFormat:@"http%@://%@:%lu", isFastCGI ? @"" : (((CRHTTPServer *)self.server).isSecure ? @"s" : @"" ),address ? : @"127.0.0.1", (unsigned long)portNumber];
    }
    baseURL = [NSURL URLWithString:baseURLString];

    [CWSitemapController rebuildSitemap];
    [[NSNotificationCenter defaultCenter] addObserverForName:CWRoutesChangedNotificationName object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [CWSitemapController rebuildSitemap];
    }];

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
    [self.server add:@"/sitemap.xml" controller:[CWSitemapController class]];
    
    // robots.txt
    [self.server add:@"/robots.txt" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        NSString* robotsString = @"User-agent: *\nAllow:\n";
        [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [response setValue:@(robotsString.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response send:robotsString];
    }}];
    
    // default.css
    [self.server mount:@"/default.css" fileAtPath:[NSBundle.mainBundle pathForResource:@"default" ofType:@"css"]];
    
//    // editor.css
//    [self.server mount:@"/editor.css" fileAtPath:[NSBundle.mainBundle pathForResource:@"editor" ofType:@"css"]];

    // hljs.css
    [self.server mount:@"/hljs.css" fileAtPath:[NSBundle.mainBundle pathForResource:@"hljs" ofType:@"css"]];

    // tokenfield.css
    [self.server mount:@"/tokenfield.css" fileAtPath:[NSBundle.mainBundle pathForResource:@"tokenfield" ofType:@"css"]];
    
    // app.js
    [self.server mount:@"/app.js" fileAtPath:[NSBundle.mainBundle pathForResource:@"app" ofType:@"js"]];

    // favicon.ico
    [self.server mount:@"/favicon.ico" fileAtPath:[NSBundle.mainBundle pathForResource:@"favicon" ofType:@"ico"]];

    [self startServer];
}

- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender {
    [CRApp logFormat:@"%@ Closing server connections.", [NSDate date]];
    [self.server closeAllConnections:^{
        [sender replyToApplicationShouldTerminate:CRTerminateNow];
    }];
    return CRTerminateLater;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [CRApp logFormat:@"%@ Sutting down server.", [NSDate date]];
    [self.server stopListening];
}

- (void)startServer {
    NSError *serverError;
    if (![self.server startListening:&serverError portNumber:portNumber]) {
        [CRApp logErrorFormat:@"%@ Failed to start HTTP server. %@", [NSDate date], serverError.localizedDescription];
        [CRApp terminate:nil];
        return;
    }

    [CRApp logFormat:@"%@ Started %@HTTP server at %@", [NSDate date], ((CRHTTPServer *)self.server).isSecure ? @"secure " : @"", baseURL];
    [CRApp logFormat:@"%@ Available paths are:", [NSDate date]];
    [self.availablePaths enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [CRApp logFormat:@"%@ * %@", [NSDate date], obj.absoluteString];
    }];
}

- (NSArray<NSURL *> *)availablePaths {
    // Get the list of paths
    NSArray<NSString *> * routePaths = [self.server valueForKeyPath:@"routes.path"];
    NSMutableArray<NSURL *> *paths = [NSMutableArray array];
    [routePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( [obj isKindOfClass:[NSNull class]] ) {
            return;
        }
        [paths addObject:[NSURL URLWithString:obj relativeToURL:baseURL]];
    }];
    
    return [paths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"absoluteString" ascending:YES]]];
}

- (void)setupHTTPS {
    NSString *certificatePath = [CWAppDelegate.baseDirectory.path stringByAppendingPathComponent:@"criollo_io.pem"];
    NSString *privateKeyPath = [CWAppDelegate.baseDirectory.path stringByAppendingPathComponent:@"criollo_io.key"];

    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL haveCertificate = [manager fileExistsAtPath:certificatePath];
    BOOL havePrivateKey = [manager fileExistsAtPath:privateKeyPath];
    
    CRHTTPServer *server = (CRHTTPServer *)self.server;
    if (!haveCertificate || !havePrivateKey) {
        [CRApp logErrorFormat:@"%@ HTTPS requested, but certificate and/or private key files were not found. Defaulting to HTTP.", [NSDate date]];
        if (!haveCertificate) {
            [CRApp logErrorFormat:@"%@ Certificate file not found: %@", [NSDate date], certificatePath];
        }
        if (!havePrivateKey) {
            [CRApp logErrorFormat:@"%@ Private key file not found: %@", [NSDate date], privateKeyPath];
        }
        server.isSecure = NO;
        return;
    }
        
    server.certificatePath = certificatePath;
    server.privateKeyPath = privateKeyPath;
    server.isSecure = YES;
}

- (void)setupBaseDirectory {
    NSError* error;
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
    NSError *error;
    _blog = [[CWBlog alloc] init];
    if (![self.blog updateAuthors:&error]) {
        [CRApp logErrorFormat:@"%@ Failed to update authors. %@", [NSDate date], error.localizedDescription];
        [CRApp terminate:nil];
    } else {
        [CRApp logFormat:@"%@ Successfully set up blog.", [NSDate date]];
    }
}

- (void)setupGithubPolling {
    NSURL *githubCacheURL = [CWAppDelegate.baseDirectory URLByAppendingPathComponent:@"github.json"];
    
    NSData *data;
    NSError *error;
    if ((data = [[NSData alloc] initWithContentsOfURL:githubCacheURL options:NSDataReadingUncached error:&error])) {
        NSArray<NSDictionary *> *objects;
        if ((objects = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error])) {
            if (!(githubRepo = [[CWGithubRepo alloc] initWithDictionary:objects[0] error:&error])) {
                [CRApp logErrorFormat:@"%@ Failed to read cached github repo info. %@", [NSDate date], error.localizedDescription];
                error = nil;
            }
            if (!(githubRelease = [[CWGithubRelease alloc] initWithDictionary:objects[1] error:&error])) {
                [CRApp logErrorFormat:@"%@ Failed to read cached release info. %@", [NSDate date], error.localizedDescription];
                error = nil;
            }
            if (!(webGithubRepo = [[CWGithubRepo alloc] initWithDictionary:objects[2] error:&error])) {
                [CRApp logErrorFormat:@"%@ Failed to read cached website github repo info. %@", [NSDate date], error.localizedDescription];
                error = nil;
            }
            [CRApp logFormat:@"%@ Successfully initialized github info from cache.", NSDate.date];
        } else {
            [CRApp logErrorFormat:@"%@ Failed to deserialize github github info cache. %@", [NSDate date], error.localizedDescription];
        }
    } else {
        [CRApp logErrorFormat:@"%@ Error reading github github info cache. %@", [NSDate date], error.localizedDescription];
    }
    
    NSTimer *timer = [[NSTimer alloc] initWithFireDate:NSDate.date interval:3600 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSError *error;
        CWGithubHelper *helper = [CWGithubHelper new];

        CWGithubRepo *repo;
        if ((repo = [helper fetchRepo:@"thecatalinstan/Criollo" error:&error])) {
            githubRepo = repo;
            [CRApp logFormat:@"%@ Successfully updated github repo info for %@", NSDate.date, githubRepo.fullName];
            
            CWGithubRelease *release;
            if((release = [helper fetchLatestReleaseForRepo:githubRepo error:&error])) {
                githubRelease = release;
                [CRApp logFormat:@"%@ Successfully updated details for release %@.", NSDate.date, githubRelease.name];
            } else {
                [CRApp logErrorFormat:@"%@ Failed to get release details. %@", NSDate.date, error.localizedDescription];
            }
        } else {
            [CRApp logErrorFormat:@"%@ Failed to get github repo details. %@", NSDate.date, error.localizedDescription];
        }
        
        CWGithubRepo *webRepo;
        if ((webRepo = [helper fetchRepo:@"thecatalinstan/Criollo-Web" error:&error])) {
            webGithubRepo = webRepo;
            [CRApp logFormat:@"%@ Successfully updated website github repo info for %@", NSDate.date, webRepo.fullName];
        } else {
            [CRApp logErrorFormat:@"%@ Failed to get website github repo details. %@", NSDate.date, error.localizedDescription];
        }
        
        NSMutableArray<CWGithubModel *> *githubInfo = [NSMutableArray arrayWithCapacity:3];
        [githubInfo addObject:githubRepo ?: [CWGithubRepo new]];
        [githubInfo addObject:githubRelease ?: [CWGithubRelease new]];
        [githubInfo addObject:webGithubRepo ?: [CWGithubRepo new]];
        
        NSArray *objects = [CWGithubModel arrayOfDictionariesFromModels:githubInfo];
        NSData *data;
        if ((data = [NSJSONSerialization dataWithJSONObject:objects options:NSJSONWritingPrettyPrinted error:&error])) {
            if ([data writeToURL:githubCacheURL options:NSDataWritingAtomic error:&error]) {
                [CRApp logFormat:@"%@ Successfully persisted github info cache.", NSDate.date];
            } else {
                [CRApp logErrorFormat:@"%@ Failed to persist github info cache. %@", NSDate.date, error.localizedDescription];
            }
        } else {
            [CRApp logErrorFormat:@"%@ Failed to serialize github info cache. %@", NSDate.date, error.localizedDescription];
        }
        
    }];
    
    [NSRunLoop.mainRunLoop addTimer:timer forMode:NSDefaultRunLoopMode];
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

+ (void)initialize {
    if (self != [CWAppDelegate class]) {
        return;
    }
    
    NSBundle *bundle = [NSBundle mainBundle];
    bundleVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    serverSpecString = [NSString stringWithFormat:@"%@, v%@ build %@", bundle.bundleIdentifier, [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
    
    baseDirectory = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSSystemDomainMask].lastObject;
    baseDirectory = [baseDirectory URLByAppendingPathComponent:[bundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleNameKey]];

    ETag = [NSUUID.UUID.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""].lowercaseString;
    
    processName = NSProcessInfo.processInfo.processName;
    processStartTime = [NSDate date];
    requestsServed = 0;
    
    backgroundQueue = dispatch_queue_create(bundle.bundleIdentifier.UTF8String, DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(backgroundQueue, dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0));
}

+ (NSString *)serverSpecString {
    return serverSpecString;
}

+ (NSString *)processName {
    return processName;
}

+ (NSString *)processRunningTime {
    return [CSTimeIntervalFormatter stringFromTimeInterval:-processStartTime.timeIntervalSinceNow].lowercaseString;
}

+ (NSString *)requestsServed {
    return [NSString stringWithFormat:@"about %@", [CSLargeNumberFormatter stringFromNumber:@(requestsServed)]];
}

+ (NSString *)bundleVersion {
    return bundleVersion;
}

+ (NSString *)ETag {
    return ETag;
}

+ (NSURL *)baseDirectory {
    return baseDirectory;
}

+ (NSURL *)baseURL {
    return baseURL;
}

+ (dispatch_queue_t)backgroundQueue {
    return backgroundQueue;
}

+ (CWGithubRepo *)githubRepo {
    return githubRepo;
}

+ (CWGithubRelease *)githubRelease {
    return githubRelease;
}

+ (CWGithubRepo *)webGithubRepo {
    return webGithubRepo;
}

@end
