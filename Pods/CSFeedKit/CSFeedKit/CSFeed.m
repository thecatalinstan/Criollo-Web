//
//  CSFeed.m
//  CSFeedKit
//
//  Created by Cătălin Stan on 31/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CSFeed.h"
#import "CSFeedChannel.h"

@implementation CSFeed

- (instancetype)init {
    return [self initWithNodeName:nil];
}

- (instancetype)initWithNodeName:(NSString *)nodeName {
    self = [super init];
    if ( self != nil ) {
        self.nodeName = nodeName ? : @"feed";
        self.namespaces = [NSMutableDictionary dictionary];
        self.channels = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithXMLElement:(NSXMLElement *)element {
    self = [self initWithNodeName:element.name];
    if ( self != nil ) {

        self.version = [element attributeForName:@"version"].stringValue;

        [element.namespaces enumerateObjectsUsingBlock:^(NSXMLNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            self.namespaces[obj.name] = obj.stringValue;
        }];

        NSArray<NSXMLElement *> * channels = [element elementsForName:@"channel"];
        [channels enumerateObjectsUsingBlock:^(NSXMLElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.channels addObject:[[CSFeedChannel alloc] initWithXMLElement:obj]];
        }];
    }
    return self;
}

- (instancetype)initWithXMLDocument:(NSXMLDocument *)document {
    return [self initWithXMLElement:document.rootElement];
}

- (instancetype)initWithXMLString:(NSString *)string error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [self initWithXMLDocument:[[NSXMLDocument alloc] initWithXMLString:string options:0 error:error]];
}

- (NSXMLDocument *)XMLDocument {
    NSXMLDocument * document = [NSXMLDocument documentWithRootElement:self.XMLElement];
    document.version = @"1.0";
    document.characterEncoding = @"utf-8";
    return document;
}

- (NSXMLElement *)XMLElement {
    NSXMLElement * element = [NSXMLElement elementWithName:self.nodeName];

    if ( self.version.length > 0 ) {
        [element addAttribute:[NSXMLNode attributeWithName:@"version" stringValue:self.version]];
    }

    [self.namespaces enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [element addAttribute:[NSXMLNode attributeWithName:[NSString stringWithFormat:@"xmlns:%@", key] stringValue:obj]];
    }];

    [self.channels enumerateObjectsUsingBlock:^(CSFeedChannel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [element addChild:obj.XMLElement];
    }];

    return element;
}


@end
