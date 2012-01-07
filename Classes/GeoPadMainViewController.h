//
//  GeoPadMainViewController.h
//  GeoJournal
//
//  Created by Jae Han on 11/19/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Three20/Three20.h>
#import "ShowDisplayOptionsView.h"

@interface GeoPadMainViewController : UINavigationController <ChangeDisplayViewDelegate> {
    UINavigationBar         *navBar;
    UIPopoverController     *displayOptionPopOver;
}

@property (nonatomic, assign)   IBOutlet    UINavigationBar *navBar;
@property (nonatomic, retain)   UIPopoverController         *displayOptionPopOver;

- (IBAction)showCategoryOptions:(id)sender;
- (IBAction)displayShowOptions:(id)sender;

@end
