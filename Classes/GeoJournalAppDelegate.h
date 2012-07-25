//
//  GeoJournalAppDelegate.h
//  GeoJournal
//
//  Created by Jae Han on 5/21/09.
//  Copyright Home 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PTPasscodeViewController.h"

@class GeoTabController;
@class ImageArrayScrollController;
@class GeoSplitViewController;
@class GeoPadMainViewController;
@class GeoPadTableViewController;

@interface GeoJournalAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, PTPasscodeViewControllerDelegate> {
    UIWindow                    *window;
    GeoTabController            *tabBarController;
    //GeoSplitViewController    *splitController;
    GeoPadMainViewController    *padMainController;
    GeoPadTableViewController   *padTableController;
	BOOL                        _inBackground;
    BOOL                        _appLaunching;
    
    UINavigationController  *_passNavController;
    
    NSInteger           _passCode;
    NSInteger           _retryPassCode;
}

@property (nonatomic, retain) IBOutlet UIWindow                 *window;
@property (nonatomic, assign) IBOutlet GeoTabController         *tabBarController;
//@property (nonatomic, assign) IBOutlet GeoSplitViewController   *splitController;
@property (nonatomic, assign) IBOutlet GeoPadMainViewController *padMainController;
@property (nonatomic, assign) GeoPadTableViewController *padTableController;

- (void)getFBExtendedPermission:(id)object;
- (void)getFBUserName:(id)object;
- (void)notifyLoggedin:(id)object;
- (void)saveAppSettings;
- (void)startLoadingImageArray:(ImageArrayScrollController*)controller;
- (UIView*)getRootView;

@end
