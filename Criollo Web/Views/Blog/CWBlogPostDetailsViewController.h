//
//  CWBlogPostView.h
//  Criollo Web
//
//  Created by Cătălin Stan on 09/04/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

@class CWBlogPost;

NS_ASSUME_NONNULL_BEGIN

@interface CWBlogPostDetailsViewController : CRViewController

@property (nonatomic, strong) CWBlogPost* post;

- (instancetype)initWithNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil post:(CWBlogPost * _Nullable)post NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END