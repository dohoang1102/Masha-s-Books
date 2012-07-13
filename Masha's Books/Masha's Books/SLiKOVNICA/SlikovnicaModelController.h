//
//  SlikovnicaModelController.h
//  SLiKOVNICA
//
//  Created by Ranko Munk on 4/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Book.h"

@class SlikovnicaDataViewController;

@interface SlikovnicaModelController : NSObject <UIPageViewControllerDataSource>

@property (strong, nonatomic) Book *book;
@property (nonatomic) BOOL textVisibility;
@property (nonatomic) BOOL voiceOverPlay;

- (SlikovnicaDataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(SlikovnicaDataViewController *)viewController;
- (NSNumber *)numberOfPages;
- (NSArray *)getPageThumbnails;

@end

