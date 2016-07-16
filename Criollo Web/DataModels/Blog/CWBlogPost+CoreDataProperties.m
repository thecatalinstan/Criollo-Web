//
//  CWBlogPost+CoreDataProperties.m
//  Criollo Web
//
//  Created by Cătălin Stan on 12/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "CWBlogPost+CoreDataProperties.h"

@implementation CWBlogPost (CoreDataProperties)

@dynamic date;
@dynamic title;
@dynamic handle;
@dynamic content;
@dynamic renderedContent;
@dynamic author;
@dynamic tags;

@end
