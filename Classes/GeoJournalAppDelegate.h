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
@class KeychainItemWrapper;

@interface GeoJournalAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, PTPasscodeViewControllerDelegate> {
    UIWindow                *window;
    GeoTabController        *tabBarController;
    KeychainItemWrapper     *passwordItem;
	BOOL                    _inBackground;
    BOOL                    _appLaunching;
    
    UINavigationController  *_passNavController;
    
    NSInteger           _passCode;
    NSInteger           _retryPassCode;
}

@property (nonatomic, retain) IBOutlet UIWindow         *window;
@property (nonatomic, retain) IBOutlet GeoTabController *tabBarController;
@property (nonatomic, retain) KeychainItemWrapper       *passwordItem;

- (void)getFBExtendedPermission:(id)object;
- (void)getFBUserName:(id)object;
- (void)notifyLoggedin:(id)object;
- (void)saveAppSettings;
- (void)startLoadingImageArray:(ImageArrayScrollController*)controller;

@end
