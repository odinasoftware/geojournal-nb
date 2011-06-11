//
//  GeoJournalAppDelegate.h
//  GeoJournal
//
//  Created by Jae Han on 5/21/09.
//  Copyright Home 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GeoTabController;

@interface GeoJournalAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    GeoTabController *tabBarController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet GeoTabController *tabBarController;


@end
