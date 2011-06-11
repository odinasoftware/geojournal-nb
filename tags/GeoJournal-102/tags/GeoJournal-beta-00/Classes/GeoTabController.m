//
//  ReaderTabController.m
//  NYTReader
//
//  Created by Jae Han on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GeoTabController.h"
#import "GeoJournalHeaders.h"
#import "NoteViewController.h"
#import "MapViewController.h"
#import "SlideShowViewController.h"
#import "MapController.h"
#import "SlideShowNavigation.h"
#import "HorizontalViewController.h"
#import "GeoDefaults.h"

/* Memory Management Strategy
 *   Uses Cases:
 *    1. NoteViewController -> JournalViewController -> JournalEntryViewController
 *       I think the image management is already efficient.
 *    2. NoteViewController -> GeoTakeController
 *       This takes up really big chunk of memory.
 *    3. SlideShowViewController -> ImageViewController -> JournalEntryViewController
 *       ImageViewController is already efficient, but need to come up with better way.
 *       May need dealloc explicitely.
 *    4. Connect
 *    5. Search.
 *    6. HorizontalViewController
 */
@implementation GeoTabController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */



- (void)viewDidLoad 
{
	//self.selectedIndex = 1;
	/*
	NSString *last_url = [[Configuration sharedConfigurationInstance] getLastUsedURLHash];
	if (last_url != nil) {
		// display history and the content
		self.selectedIndex = 2;
	}
	 */
}

- (void)viewDidAppear
{
	[GeoDefaults sharedGeoDefaultsInstance].firstLevel = -1;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	/*
	BOOL shouldAllowRotate = (interfaceOrientation == UIInterfaceOrientationPortrait);
	UIViewController *controller = self.selectedViewController;
	
	if ([controller isKindOfClass:[MapController class]] == YES) {
		shouldAllowRotate = YES;
	}
	else if ([controller isKindOfClass:[SlideShowNavigation class]] == YES) {
		shouldAllowRotate = YES;
	}
	
	TRACE("%s, %d\n", __func__, shouldAllowRotate);
	 */
	BOOL shouldAllowRotate = YES;
	
	return shouldAllowRotate;
}

/*
 * Special horizontal view implementation.
 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	TRACE_HERE;
	
	UIViewController *c = self.selectedViewController;
	
	if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft||
		toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
		if ([c isKindOfClass:[UINavigationController class]] == YES) {
			HorizontalViewController *controller = [[HorizontalViewController alloc] initWithNibName:@"HorizontalViewController" bundle:nil];
			
			UINavigationController *nav = (UINavigationController*) c;
			nav.navigationBarHidden = YES;
			controller.hidesBottomBarWhenPushed = YES;
			controller.view.frame = CGRectMake(0.0, 0.0, 480.0, 320.0);
			[nav pushViewController:controller animated:NO];
			[controller release];
		}
	}
	else {
		if ([c isKindOfClass:[UINavigationController class]] == YES) {
			UINavigationController *nav = (UINavigationController*) c;
			nav.navigationBarHidden = NO;
			UIViewController *c = [nav popViewControllerAnimated:NO];
			[c release];
		}
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	TRACE_HERE;
	/*
	UIViewController *c = self.selectedViewController;
	
	if (fromInterfaceOrientation == UIInterfaceOrientationPortrait ||
		fromInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
		if ([c isKindOfClass:[UINavigationController class]] == YES) {
			HorizontalViewController *controller = [[HorizontalViewController alloc] initWithNibName:@"HorizontalViewController" bundle:nil];
			
			UINavigationController *nav = (UINavigationController*) c;
			nav.navigationBarHidden = YES;
			controller.hidesBottomBarWhenPushed = YES;
			controller.view.frame = CGRectMake(0.0, 0.0, 480.0, 320.0);
			[nav pushViewController:controller animated:NO];
			[controller release];
		}
	}
	else {
		if ([c isKindOfClass:[UINavigationController class]] == YES) {
			UINavigationController *nav = (UINavigationController*) c;
			nav.navigationBarHidden = NO;
			[nav popViewControllerAnimated:NO];
		}
	}
	*/
}

/*
- (UIView *)rotatingFooterView
{
	return nil;
}

- (UIView *)rotatingHeaderView
{
	return nil;
}
*/

- (void)didReceiveMemoryWarning {
	NSLog(@"%s", __func__);
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[super dealloc];
}


@end
