//
//  CSRSSFeedItem.m
//  CSFeedKit
//
//  Created by Cătălin Stan on 31/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CSRSSFeedItem.h"

@implementation CSRSSFeedItem

- (instancetype)initWithXMLElement:(NSXMLElement *)element {
    self = [super initWithXMLElement:element];
    if ( self != nil ) {
        self.creator = [element elementsForName:@"dc:creator"].firstObject.stringValue;
    }
    return self;
}

- (NSXMLElement *)XMLElement {
    NSXMLElement * element = [super XMLElement];
    if ( self.creator.length > 0 ) {
        [element addChild:[NSXMLElement elementWithName:@"dc:creator" stringValue:self.creator]];
    }
    return element;
}

@end
