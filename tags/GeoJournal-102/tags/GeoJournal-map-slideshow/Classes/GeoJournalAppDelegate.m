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

#define	CONNECT_CONTROLLER_INDEX	2

@implementation GeoJournalAppDelegate

@synthesize window;
@synthesize tabBarController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:tabBarController.view];
	
	[GeoDefaults sharedGeoDefaultsInstance];
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
- (void)applicationWillTerminate:(UIApplication *)application
{
	// save the drill-down hierarchy of selections to preferences
	[[GeoDefaults sharedGeoDefaultsInstance] saveDefaultSettings];
}

- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end

