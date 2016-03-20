//
//  AppDelegate.m
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "AppDelegate.h"
#import "CWLandingPageViewController.h"

#include <stdio.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <sys/utsname.h>

#define PortNumber          10781
#define LogConnections          0
#define LogRequests             1


NS_ASSUME_NONNULL_BEGIN
@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong) CRHTTPServer *server;

- (void)startServer;

@end
NS_ASSUME_NONNULL_END

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    processStartTime = [NSDate date];
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
    [self.server addController:[CWLandingPageViewController class] withNibName:@"CWLandingPageViewController" bundle:nil forPath:@"/"];

    // robot.txt
    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSString* robotsString = @"User-agent: *\nAllow:\n";
        [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [response setValue:@(robotsString.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response send:robotsString];
        completionHandler();
    } forPath:@"/robots.txt"];

    // favicon.ico
    NSString* faviconPath = [bundle pathForResource:@"favicon" ofType:@"ico"];
    [self.server mountStaticFileAtPath:faviconPath forPath:@"/favicon.ico"];

    // Static resources folder
    NSString* publicResourcesFolder = [bundle.resourcePath stringByAppendingPathComponent:@"Public"];
    [self.server mountStaticDirectoryAtPath:publicResourcesFolder forPath:CWStaticDirPath options:CRStaticDirectoryServingOptionsCacheFiles];

    [self startServer];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.server stopListening];
}

- (void)startServer {
    NSError *serverError;

    if ( [self.server startListening:&serverError portNumber:PortNumber] ) {

        // Get server ip address

        NSString* address = [AppDelegate IPAddress];
        if ( !address ) {
            address = @"127.0.0.1";
        }

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
    NSString* remoteAddress = request.env[@"HTTP_X_FORWARDED_FOR"].length > 0 ? request.env[@"HTTP_X_FORWARDED_FOR"] : request.connection.remoteAddress;
    NSUInteger statusCode = request.response.statusCode;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [CRApp logFormat:@"%@ %@ %@ - %lu %@ - %@", [NSDate date], remoteAddress, request, statusCode, contentLength ? : @"-", userAgent];
    });
}
#endif

#pragma mark - Utils

+ (NSString *)IPAddress {
    static NSString* address;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct ifaddrs *interfaces = NULL;
        struct ifaddrs *temp_addr = NULL;
        int success = 0;
        success = getifaddrs(&interfaces);
        if (success == 0) {
            temp_addr = interfaces;
            while(temp_addr != NULL) {
                if(temp_addr->ifa_addr->sa_family == AF_INET) {
                    if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                        address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    }
                }
                temp_addr = temp_addr->ifa_next;
            }
        }
        freeifaddrs(interfaces);
    });
    return address;
}

+ (NSString*)systemInfo {
    static NSString* systemInfo;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct utsname unameStruct;
        uname(&unameStruct);
        systemInfo = [NSString stringWithFormat:@"%s %s %s %s %s", unameStruct.sysname, unameStruct.nodename, unameStruct.release, unameStruct.version, unameStruct.machine];
    });
    return systemInfo;
}

+ (NSString*)systemVersion {
    static NSString* publicSystemInfo;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct utsname unameStruct;
        uname(&unameStruct);
        publicSystemInfo = [NSString stringWithFormat:@"%s %s/%s", unameStruct.sysname, unameStruct.release, unameStruct.machine];
    });
    return publicSystemInfo;
}

+ (NSString *)processRunningTime {
    NSTimeInterval processRunningTime = processStartTime.timeIntervalSinceNow;
    NSString* processRunningTimeString;

    static NSDateComponentsFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateComponentsFormatter alloc] init];
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
        formatter.includesApproximationPhrase = YES;
        formatter.includesTimeRemainingPhrase = NO;
        formatter.allowedUnits = NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear;
    });

    processRunningTimeString = [formatter stringFromTimeInterval:fabs(processRunningTime)];
    return processRunningTimeString.lowercaseString;
}

+ (NSString *)memoryInfo:(NSError * _Nullable __autoreleasing *)error {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    if( kerr == KERN_SUCCESS ) {
        return [NSByteCountFormatter stringFromByteCount:info.resident_size countStyle:NSByteCountFormatterCountStyleMemory];
    } else {
        *error = [NSError errorWithDomain:[NSProcessInfo processInfo].processName code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s",mach_error_string(kerr)]}];
        return nil;
    }
}

+ (NSString *)criolloVersion {
    static NSString* criolloVersion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *criolloBundle = [NSBundle bundleForClass:[CRServer class]];
        criolloVersion = [criolloBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if ( criolloVersion == nil ) {
            criolloVersion = CWCriolloVersion;
        }
    });
    return criolloVersion;
}

+ (NSString *)bundleVersion {
    static NSString* bundleVersion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle mainBundle];
        bundleVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    });
    return bundleVersion;
}

+ (NSString *)ETag {
    static NSString* ETag;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ETag = [[NSUUID UUID].UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""].lowercaseString;
    });
    return ETag;
}

@end
