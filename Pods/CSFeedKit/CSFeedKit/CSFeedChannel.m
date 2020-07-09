//
//  CSFeedChannel.m
//  CSFeedKit
//
//  Created by Cătălin Stan on 31/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CSFeedChannel.h"
#import "CSFeedItem.h"
#import "CSRFC2822DateFormatter.h"

@implementation CSFeedChannel

- (instancetype)init {
    return [self initWithTitle:@"" link:@"" description:@""];
}

- (instancetype)initWithTitle:(NSString *)title link:(NSString *)link description:(NSString *)description {
    self = [super init];
    if ( self != nil ) {
        self.title = title;
        self.link = link;
        self.channelDescription = description;
        self.items = [NSMutableArray array];

        NSBundle * bundle = [NSBundle mainBundle];
        self.generator = [NSString stringWithFormat:@"%@, v%@ build %@", bundle.bundleIdentifier, [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
        self.lastBuildDate = [NSDate date];
        self.pubDate = [NSDate date];
        self.language = [NSLocale preferredLanguages].firstObject;

        self.ttl = 3600;
    }
    return self;
}

- (instancetype)initWithXMLElement:(NSXMLElement *)element {
    NSString * title = [element elementsForName:@"title"].firstObject.stringValue;
    NSString * link = [element elementsForName:@"link"].firstObject.stringValue;
    NSString * description = [element elementsForName:@"description"].firstObject.children.firstObject.stringValue;

    self = [self initWithTitle:title link:link description:description];
    if ( self != nil ) {
        self.category = [element elementsForName:@"category"].firstObject.stringValue;
        self.generator = [element elementsForName:@"generator"].firstObject.stringValue;
        self.language = [element elementsForName:@"language"].firstObject.stringValue;

        NSXMLElement * ttlElement = [element elementsForName:@"ttl"].firstObject;
        if ( ttlElement ) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            self.ttl = [formatter numberFromString:ttlElement.stringValue].integerValue;
        }

        NSXMLElement * lastBuildDateElement = [element elementsForName:@"lastBuildDate"].firstObject;
        if ( lastBuildDateElement ) {
            self.lastBuildDate = [[CSRFC2822DateFormatter sharedInstance] dateFromString:lastBuildDateElement.stringValue];
        }

        NSXMLElement * pubDateElement = [element elementsForName:@"pubDate"].firstObject;
        if ( pubDateElement ) {
            self.pubDate = [[CSRFC2822DateFormatter sharedInstance] dateFromString:pubDateElement.stringValue];
        }

        NSArray<NSXMLElement *> * items = [element elementsForName:@"item"];
        [items enumerateObjectsUsingBlock:^(NSXMLElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.items addObject:[[CSFeedItem alloc] initWithXMLElement:obj]];
        }];
    }
    return self;
}

- (instancetype)initWithXMLString:(NSString *)string error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [self initWithXMLElement:[[NSXMLElement alloc] initWithXMLString:string error:error]];
}

- (NSXMLElement *)XMLElement {

    NSXMLElement * element = [NSXMLElement elementWithName:@"channel"];
    [element addChild:[NSXMLElement elementWithName:@"title" stringValue:self.title]];
    [element addChild:[NSXMLElement elementWithName:@"link" stringValue:self.link]];

    NSXMLElement * descElement = [NSXMLElement elementWithName:@"description"];
    NSXMLNode * cdataDescNode = [[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
    cdataDescNode.stringValue = self.channelDescription;
    [descElement addChild:cdataDescNode];
    [element addChild:descElement];

    if ( self.generator.length > 0 ) {
        [element addChild:[NSXMLElement elementWithName:@"generator" stringValue:self.generator]];
    }

    NSString *lastBuildDateString = [[CSRFC2822DateFormatter sharedInstance] stringFromDate:self.lastBuildDate];
    [element addChild:[NSXMLElement elementWithName:@"lastBuildDate" stringValue:lastBuildDateString]];

    NSString *pubDateString = [[CSRFC2822DateFormatter sharedInstance] stringFromDate:self.pubDate];
    [element addChild:[NSXMLElement elementWithName:@"pubDate" stringValue:pubDateString]];

    if ( self.language.length > 0 ) {
        [element addChild:[NSXMLElement elementWithName:@"language" stringValue:self.language]];
    }

    if ( self.ttl > 0 ) {
        [element addChild:[NSXMLElement elementWithName:@"ttl" stringValue:@(self.ttl).stringValue]];
    }

    if ( self.category.length > 0 ) {
        [element addChild:[NSXMLElement elementWithName:@"category" stringValue:self.category]];
    }

    [self.items enumerateObjectsUsingBlock:^(CSFeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [element addChild:obj.XMLElement];
    }];

    return element;
}

@end
