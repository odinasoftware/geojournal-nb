//
//  GeoPadMainViewController.h
//  GeoJournal
//
//  Created by Jae Han on 11/19/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShowDisplayOptionsView.h"

@interface GeoPadMainViewController : UINavigationController <ChangeDisplayViewDelegate> {
    UINavigationBar     *navBar;
}

@property (nonatomic, assign)   IBOutlet    UINavigationBar *navBar;

- (IBAction)showCategoryOptions:(id)sender;
- (IBAction)displayShowOptions:(id)sender;

@end
