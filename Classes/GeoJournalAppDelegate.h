//
//  GeoJournalAppDelegate.h
//  GeoJournal
//
//  Created by Jae Han on 5/21/09.
//  Copyright Home 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GeoTabController;
@class ImageArrayScrollController;

@interface GeoJournalAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    GeoTabController *tabBarController;
	BOOL	_inBackground;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet GeoTabController *tabBarController;

- (void)getFBExtendedPermission:(id)object;
- (void)getFBUserName:(id)object;
- (void)notifyLoggedin:(id)object;
- (void)saveAppSettings;
- (void)startLoadingImageArray:(ImageArrayScrollController*)controller;

@end
