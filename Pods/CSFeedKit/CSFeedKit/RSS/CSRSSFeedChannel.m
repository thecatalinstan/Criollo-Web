//
//  CSRSSFeedChannel.m
//  CSFeedKit
//
//  Created by Cătălin Stan on 31/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CSRSSFeedChannel.h"
#import "CSRSSFeedItem.h"

@implementation CSRSSFeedChannel

- (instancetype)initWithXMLElement:(NSXMLElement *)element {
    self = [super initWithXMLElement:element];
    if ( self != nil ) {
        [self.items removeAllObjects];
        NSArray<NSXMLElement *> * items = [element elementsForName:@"item"];
        [items enumerateObjectsUsingBlock:^(NSXMLElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.items addObject:[[CSRSSFeedItem alloc] initWithXMLElement:obj]];
        }];
    }
    return self;
}

@end
