//
//  GeoJournalAppDelegate.m
//  GeoJournal
//
//  Created by Jae Han on 5/21/09.
//  Copyright Home 2009. All rights reserved.
//

#import "GeoJournalAppDelegate.h"
#import "GeoDefaults.h"
#import "ConnectViewController.h"
#import "GeoTabController.h"
#import "GeoJournalHeaders.h"
#import "GeoSession.h"
#import "CameraThread.h"

#define	CONNECT_CONTROLLER_INDEX	2

@implementation GeoJournalAppDelegate

@synthesize window;
@synthesize tabBarController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[GeoDefaults sharedGeoDefaultsInstance];
    
	// TODO: read the saved location and show it.
    // Add the tab bar controller's current view as a subview of the window
	if ([GeoDefaults sharedGeoDefaultsInstance].firstLevel > -1) {
		int i = [GeoDefaults sharedGeoDefaultsInstance].firstLevel;
		TRACE("%s, index: %d\n", __func__, i);
		self.tabBarController.selectedIndex = i;
	}
    [window addSubview:tabBarController.view];
	
	//CameraThread *thread = [CameraThread sharedCameraControllerInstance];
	
	//[thread start];
	
}


/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
}
*/

/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/

/*
#pragma mark Facebook callbacks
-(void)fbUserDidLogin:(id)sender
{
	UINavigationController *navigationc = [[self.tabBarController viewControllers] objectAtIndex:CONNECT_CONTROLLER_INDEX];
	if (navigationc && [navigationc isKindOfClass:[UINavigationController class]]) {
		UIViewController *v = [navigationc visibleViewController];
		if ([v isKindOfClass:[ConnectViewController class]]) {
			[(ConnectViewController*)v fbUserDidLogin];
		}
	}
}

#pragma mark -
*/

#pragma mark FACEBOOK
- (void)getFBExtendedPermission:(id)object 
{
	// get extended permission.
	[[GeoSession sharedGeoSessionInstance] getExtendedPermission:object];
}

- (void)getFBUserName:(id)object
{
	id delegate = object;
	
	NSString* fql = [[NSString alloc] initWithFormat:@"select name from user where uid == %qu", [GeoSession sharedGeoSessionInstance].fbUID];
	
	NSDictionary* params = [NSDictionary dictionaryWithObject:fql forKey:@"query"];
	
	if (object == nil) {
		delegate = [GeoSession sharedGeoSessionInstance];
	}
	[[FBRequest requestWithDelegate:delegate] call:@"facebook.fql.query" params:params];	
}

#pragma mark -
- (void)applicationWillTerminate:(UIApplication *)application
{
	// save the drill-down hierarchy of selections to preferences
	[GeoDefaults sharedGeoDefaultsInstance].firstLevel = self.tabBarController.selectedIndex;
	[[GeoDefaults sharedGeoDefaultsInstance] saveDefaultSettings];
}

- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end

