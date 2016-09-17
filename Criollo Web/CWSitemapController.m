//
//  CWSitemapController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 17/09/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWSitemapController.h"
#import "CWAppDelegate.h"
#import "CWBlog.h"
#import "CWBlogPost.h"
#import "CWBlogTag.h"
#import "CWBlogAuthor.h"

@implementation CWSitemapController

- (instancetype)initWithPrefix:(NSString *)prefix {
    self = [super initWithPrefix:prefix];
    if ( self != nil ) {
        [self setupRoutes];
    }
    return self;
}

- (NSXMLElement *)sitemapURLElementWithPath:(NSString *)path {
    NSXMLElement * urlElement = [NSXMLElement elementWithName:@"url"];
    [urlElement addChild:[NSXMLElement elementWithName:@"loc" stringValue:[NSURL URLWithString:path relativeToURL:[CWAppDelegate baseURL]].absoluteString]];
    return urlElement;
}

- (NSData *)generateSitemap:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSXMLElement *rootNode = [[NSXMLElement alloc] initWithName:@"urlset"];
    [rootNode addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.sitemaps.org/schemas/sitemap/0.9"]];
    [rootNode addNamespace:[NSXMLNode predefinedNamespaceForPrefix:@"xsi"]];
    [rootNode addAttribute:[NSXMLNode attributeWithName:@"xsi:schemaLocation" stringValue:@"http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"]];

    // root
    [rootNode addChild:[self sitemapURLElementWithPath:CRPathSeparator]];

    // blog
    [rootNode addChild:[self sitemapURLElementWithPath:CWBlogPath]];

    // posts
    RLMResults * posts = [CWBlogPost getObjectsWhere:@"published=true"];
    for ( CWBlogPost *post in posts ) {
        [rootNode addChild:[self sitemapURLElementWithPath:post.publicPath]];
    }

    // tags
    RLMResults * tags = [CWBlogTag allObjectsInRealm:[CWBlog realm]];
    for ( CWBlogTag *tag in tags ) {
        [rootNode addChild:[self sitemapURLElementWithPath:tag.publicPath]];
    }

    // authors
    RLMResults * authors = [CWBlogAuthor allObjectsInRealm:[CWBlog realm]];
    for ( CWBlogTag *author in authors ) {
        [rootNode addChild:[self sitemapURLElementWithPath:author.publicPath]];
    }

    NSXMLDocument *xml = [[NSXMLDocument alloc] initWithRootElement:rootNode];
    return [xml XMLDataWithOptions:0];
}

- (void)setupRoutes {
    [self get:CRPathSeparator  block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) { @autoreleasepool {
        [response setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response sendData:[self generateSitemap:nil]];
    }}];
}

@end
