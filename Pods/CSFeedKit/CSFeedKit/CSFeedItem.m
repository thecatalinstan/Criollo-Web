//
//  CSFeedItem.m
//  CSFeedKit
//
//  Created by Cătălin Stan on 30/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CSFeedItem.h"
#import "CSRFC2822DateFormatter.h"

@implementation CSFeedItem

- (instancetype)init {
    return [self initWithTitle:@"" link:@"" description:@""];
}

- (instancetype)initWithTitle:(NSString *)title link:(NSString *)link description:(NSString *)description {
    self = [super init];
    if ( self != nil ) {
        self.title = title;
        self.link = link;
        self.itemDescription = description;
        self.GUID = self.link;
        self.GUIDIsPermaLink = YES;
        self.pubDate = [NSDate date];
    }
    return self;
}

- (instancetype)initWithXMLElement:(NSXMLElement *)element {
    NSString * title = [element elementsForName:@"title"].firstObject.stringValue;
    NSString * link = [element elementsForName:@"link"].firstObject.stringValue;
    NSString * description = [element elementsForName:@"description"].firstObject.children.firstObject.stringValue;

    self = [self initWithTitle:title link:link description:description];
    if ( self != nil ) {
        self.comments = [element elementsForName:@"comments"].firstObject.stringValue;
        self.info = [element elementsForName:@"info"].firstObject.stringValue;

        NSXMLElement * GUIDElement = [element elementsForName:@"guid"].firstObject;
        self.GUID = GUIDElement.stringValue;
        self.GUIDIsPermaLink = [[GUIDElement attributeForName:@"isPermaLink"].stringValue isEqualToString:@"true"];

        NSXMLElement * dateElement = [element elementsForName:@"pubDate"].firstObject;
        if ( dateElement ) {
            self.pubDate = [[CSRFC2822DateFormatter sharedInstance] dateFromString:dateElement.stringValue];
        }
    }
    return self;
}

- (instancetype)initWithXMLString:(NSString *)string error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [self initWithXMLElement:[[NSXMLElement alloc] initWithXMLString:string error:error]];
}

- (NSXMLElement *)XMLElement {
    NSXMLElement * element = [NSXMLElement elementWithName:@"item"];

    [element addChild:[NSXMLElement elementWithName:@"title" stringValue:self.title]];
    [element addChild:[NSXMLElement elementWithName:@"link" stringValue:self.link]];
    [element addChild:[NSXMLElement elementWithName:@"comments" stringValue:self.comments]];

    NSXMLElement * GUIDElement = [NSXMLElement elementWithName:@"guid" stringValue:self.GUID];
    [GUIDElement setAttributesWithDictionary:@{@"isPermaLink" : self.GUIDIsPermaLink ? @"true" : @"false" }];
    [element addChild:GUIDElement];

    NSString *dateString = [[CSRFC2822DateFormatter sharedInstance] stringFromDate:self.pubDate];
    [element addChild:[NSXMLElement elementWithName:@"pubDate" stringValue:dateString]];

    NSXMLElement * descElement = [NSXMLElement elementWithName:@"description"];
    NSXMLNode * cdataDescNode = [[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
    cdataDescNode.stringValue = self.itemDescription;
    [descElement addChild:cdataDescNode];
    [element addChild:descElement];

    if ( self.info.length > 0 ) {
        [element addChild:[NSXMLElement elementWithName:@"info" stringValue:self.info]];
    }

    return element;
}

@end
