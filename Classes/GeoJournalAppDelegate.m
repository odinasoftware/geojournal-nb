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
#import "KeychainItemWrapper.h"
//#import "SpeakHereController.h"

#define	CONNECT_CONTROLLER_INDEX	2

@implementation GeoJournalAppDelegate

@synthesize window;
@synthesize tabBarController;

- (void)startTabBarView
{

    if ([GeoDefaults sharedGeoDefaultsInstance].firstLevel > -1) {
        int i = [GeoDefaults sharedGeoDefaultsInstance].firstLevel;
        TRACE("%s, index: %d\n", __func__, i);
        self.tabBarController.selectedIndex = i;
    }
    [window addSubview:tabBarController.view];
    _inBackground = NO;
        
}

- (void)openPasscodeController
{
    _passCode = [[GeoDefaults sharedGeoDefaultsInstance] getPasscode];
    TRACE("%s, passcode: %d\n", __func__, _passCode);

    PTPasscodeViewController *passcodeViewController = [[PTPasscodeViewController alloc] initWithDelegate:self passcode:NO];
    
    _passNavController = [[UINavigationController alloc]
                          initWithRootViewController:passcodeViewController];
    [window addSubview:[_passNavController view]];
    [passcodeViewController release];
    //[_passNavController release];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    BOOL passcode_presented = NO;
    _appLaunching = YES;
    TRACE_HERE;
	[GeoDefaults sharedGeoDefaultsInstance];
    
	// TODO: read the saved location and show it.
    // Add the tab bar controller's current view as a subview of the window
    
    if (([[GeoDefaults sharedGeoDefaultsInstance].defaultInitDone intValue] == 0) ||
        ([[GeoDefaults sharedGeoDefaultsInstance].isPrivate intValue] == 1)) {

        _passCode = [[GeoDefaults sharedGeoDefaultsInstance] getPasscode];
        TRACE("%s, password: %d\n", __func__, _passCode);
        
        // This is first run, set up password
        [self openPasscodeController];
        
    }
    else {
        [self startTabBarView];
    }
	//CameraThread *thread = [CameraThread sharedCameraControllerInstance];
	
	//[thread start];
	
}

#pragma PTPasscode
- (void) didShowPasscodePanel:(PTPasscodeViewController *)passcodeViewController panelView:(UIView*)panelView
{
    TRACE_HERE;
    [passcodeViewController setTitle:@"Set Passcode"];
    // Please enter your passcode to log on
    // Incorrect passcode. Try again.
    if([panelView tag] == kPasscodePanelOne) {
        [[passcodeViewController titleLabel] setText:@"Please enter your passcode to start."];
    }
    
    if([panelView tag] == kPasscodePanelTwo) {
        [[passcodeViewController titleLabel] setText:@"Incorrect passcode. Try again."];
    }
    
    if([panelView tag] == kPasscodePanelThree) {
        [[passcodeViewController titleLabel] setText:@"Incorrect passcode. Try again."];
    }
}

- (BOOL)shouldChangePasscode:(PTPasscodeViewController *)passcodeViewController panelView:(UIView*)panelView passCode:(NSUInteger)passCode lastNumber:(NSInteger)lastNumber;
{
    TRACE_HERE;
    // Clear summary text
    [[passcodeViewController summaryLabel] setText:@""];
    
    return TRUE;
}

- (BOOL)didEndPasscodeEditing:(PTPasscodeViewController *)passcodeViewController panelView:(UIView*)panelView passCode:(NSUInteger)passCode
{
    
    NSLog(@"END PASSCODE - %d", passCode);
    
    if([panelView tag] == kPasscodePanelOne) {
        if (_passCode != passCode) {
            
            
            /*if(_passCode != passCode) {
             [[passcodeViewController summaryLabel] setText:@"Invalid PIN code"];
             [[passcodeViewController summaryLabel] setTextColor:[UIColor redColor]];
             [passcodeViewController clearPanel];
             return FALSE;
             }*/
            
            return ![passcodeViewController nextPanel];
        }
       
    }
    else if([panelView tag] == kPasscodePanelTwo) {
        if (_passCode != passCode) {
            [passcodeViewController nextPanel];
            [[passcodeViewController summaryLabel] setText:@"Passcode did not match. Try again."];
            return FALSE;
        }
    }
    else if ([panelView tag] == kPasscodePanelThree) {
        if (_passCode != passCode) {
            [passcodeViewController prevPanel];
            [[passcodeViewController summaryLabel] setText:@"Passcode did not match. Try again."];
            return FALSE;
        }
    }
    
    if (_passNavController) {
        [_passNavController popViewControllerAnimated:YES];
        [[_passNavController view] removeFromSuperview];
        [_passNavController release];
    }
    
    [self startTabBarView];
    //  return ![passcodeView nextPanel];
    
    return TRUE;
}

#pragma -
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
    _appLaunching = NO;
	[self saveAppSettings];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	UINavigationController *controller = nil;
	GeoTakeController *take = nil;
	TRACE_HERE;
	if (_inBackground) {
		controller = (UINavigationController*)[self.tabBarController selectedViewController];
		if ([controller.visibleViewController isKindOfClass:[GeoTakeController class]]) {
			take = (GeoTakeController*) controller.visibleViewController;
			
			[take.audioController restartRecoding];
         
			_inBackground = NO;
		}
        
	}
    // TODO: taking care of when view is not unloaded.
    if (_appLaunching == NO && ([[GeoDefaults sharedGeoDefaultsInstance].isPrivate intValue] == 1)) {
        [self openPasscodeController];
    }
}

- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end

