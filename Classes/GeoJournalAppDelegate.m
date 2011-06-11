//
//  GeoJournalAppDelegate.m
//  GeoJournal
//
//  Created by Jae Han on 5/21/09.
//  Copyright Home 2009. All rights reserved.
//

#import "GeoJournalAppDelegate.h"
#import "GeoDefaults.h"
#import "ConnectController.h"
#import "ConnectViewController.h"
#import "GeoTabController.h"
#import "GeoJournalHeaders.h"
#import "GeoSession.h"
#import "CameraThread.h"
#import "ImageArrayScrollController.h"
#import "GeoTakeController.h"
//#import "SpeakHereController.h"

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
	_inBackground = NO;
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
	
	/*
	NSString* fql = [[NSString alloc] initWithFormat:@"select name from user where uid == %qu", [GeoSession sharedGeoSessionInstance].fbUID];
	
	NSDictionary* params = [NSDictionary dictionaryWithObject:fql forKey:@"query"];
	
	if (object == nil) {
		delegate = [GeoSession sharedGeoSessionInstance];
	}
	[[FBRequest requestWithDelegate:delegate] call:@"facebook.fql.query" params:params];	
	 */
}

- (void)notifyLoggedin:(id)object
{
	UIViewController *n = tabBarController.selectedViewController;
	
	if ([n isKindOfClass:[ConnectController class]] == YES) {
		UIViewController *v = [(ConnectController*)n visibleViewController];
		if ([v isKindOfClass:[ConnectViewController class]] == YES) {
			[((ConnectViewController*)v)._tableView reloadData];
		}
	}
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	[[GeoSession sharedGeoSessionInstance].facebook handleOpenURL:url];
	[[GeoSession sharedGeoSessionInstance] getAuthorization:nil];
	
	return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	[[GeoSession sharedGeoSessionInstance].facebook handleOpenURL:url];

	return YES;
}
#pragma mark -
#pragma mark callbacks
- (void)startLoadingImageArray:(ImageArrayScrollController*)controller
{
	[controller startLoadingImages];
}

- (void)saveAppSettings
{
	// save the drill-down hierarchy of selections to preferences
	[GeoDefaults sharedGeoDefaultsInstance].firstLevel = self.tabBarController.selectedIndex;
	[[GeoDefaults sharedGeoDefaultsInstance] saveDefaultSettings];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[self saveAppSettings];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	GeoTakeController *take = nil;
	UINavigationController *controller = (UINavigationController*) [self.tabBarController selectedViewController];
	
	if (controller && controller.topViewController) {
		if ([controller.visibleViewController isKindOfClass:[GeoTakeController class]]) {
			take = (GeoTakeController*) controller.visibleViewController;
			
			[take.audioController pauseRecord];
			_inBackground = YES;
		}
	}
	[self saveAppSettings];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	UINavigationController *controller = nil;
	GeoTakeController *take = nil;
	
	if (_inBackground) {
		controller = (UINavigationController*)[self.tabBarController selectedViewController];
		if ([controller.visibleViewController isKindOfClass:[GeoTakeController class]]) {
			take = (GeoTakeController*) controller.visibleViewController;
			
			[take.audioController restartRecoding];
			_inBackground = NO;
		}
	}
}

- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end

