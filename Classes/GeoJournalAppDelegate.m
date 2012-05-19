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
#import "GeoSplitViewController.h"
#import "JournalEntryViewController.h"
#import "GeoSplitTableController.h"
#import "GeoPadMainViewController.h"
#import "GeoDatabase.h"
//#import "SpeakHereController.h"
#import "CloudService.h"
#import "CloudFileService.h"
#import "ProgressViewController.h"

#define	CONNECT_CONTROLLER_INDEX	2

@implementation GeoJournalAppDelegate

@synthesize window;
@synthesize tabBarController;
//@synthesize splitController;
@synthesize padMainController;

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

// Method invoked when notifications of content batches have been received
- (void)queryDidUpdate:sender;
{
    NSLog(@"A data batch has been received");
}


// Method invoked when the initial query gathering is completed
- (void)initalGatherComplete:sender;
{
    NSMetadataQuery *query = [sender object];
    
    TRACE("%s, %d\n", __func__, [query resultCount]);
    
    // Stop the query, the single pass is completed.
    [query stopQuery];
    
    if ([query resultCount] == 0) {
        // No file exists. If local exists, then upload it.
        // Otherwise, there is no image. 
        
    }
    // Process the content. In this case the application simply
    // iterates over the content, printing the display name key for
    // each image
    NSInteger i=0;
    for (i=0; i < [query resultCount]; i++) {
        NSMetadataItem *theResult = [query resultAtIndex:i];
        NSURL *fileURL = [theResult valueForAttribute:(NSString *)NSMetadataItemURLKey];
        NSNumber *aBool = nil;
        NSError *error = nil;
        [fileURL getResourceValue:&aBool forKey:NSURLIsHiddenKey error:&error];
        if (aBool && ![aBool boolValue]) {
            TRACE("result at %d - %s\n", i, [[fileURL absoluteString] UTF8String]);
        }
    }
    
    // Remove the notifications to clean up after ourselves.
    // Also release the metadataQuery.
    // When the Query is removed the query results are also lost.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidUpdateNotification
                                                  object:query];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidFinishGatheringNotification
                                                  object:query];
    [query release];
}


- (void)searchInCloud:(NSString*)url
{
    TRACE("%s, url: %s, %s\n", __func__, [url UTF8String], [NSMetadataQueryUbiquitousDataScope UTF8String]);
    NSMetadataQuery *metadataSearch = [[NSMetadataQuery alloc] init];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K like %@", NSMetadataItemFSNameKey, url];
    [metadataSearch setPredicate:predicate];
    
    // Register the notifications for batch and completion updates
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryDidUpdate:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:metadataSearch];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initalGatherComplete:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:metadataSearch];
    
    // Set the search scope. In this case it will search the User's home directory
    // and the iCloud documents area
    NSArray *searchScopes;
    searchScopes=[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDataScope, nil];
    [metadataSearch setSearchScopes:searchScopes];
    
    // Configure the sorting of the results so it will order the results by the
    // display name
    /*
     NSSortDescriptor *sortKeys=[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemDisplayName
     ascending:YES] autorelease];
     [metadataSearch setSortDescriptors:[NSArray arrayWithObject:sortKeys]];
     */
    TRACE("metadata search: %d, gathering: %d, stopped: %d, count: %d\n", [metadataSearch isStarted], [metadataSearch isGathering], [metadataSearch isStopped], [metadataSearch resultCount]);
    if ([metadataSearch startQuery] == NO) {
        TRACE("%s, query failed.\n", __func__);
    }
    
}

- (void)checkInSyncWithCloud
{    
    CloudFileService *service = [[CloudFileService alloc] init];
    
    if ([service isFilesInCloud] == NO) {
        [[ProgressViewControllerHolder sharedStatusViewControllerInstance] showStatusView:self.tabBarController.view type:DEFAULT_PROGRESS_TYPE];
        
        // TODO: we do not have anything in the cloud, need to them into it. 
        // TODO: check if this is cloud ready, the files has to be unique.
        // enumerate it from the local and copy to the cloud sandbox.
        
        [service copyToCloudSandbox];
        
    }
    
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    BOOL passcode_presented = NO;
    _appLaunching = YES;
    TRACE_HERE;
	[GeoDefaults sharedGeoDefaultsInstance];
    
	// TODO: read the saved location and show it.
    // Add the tab bar controller's current view as a subview of the window
    /*
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
        
        //UINavigationController *masterNavigationController = [splitViewController.viewControllers objectAtIndex:0];
        //MasterViewController *controller = (MasterViewController *)masterNavigationController.topViewController;
        //controller.managedObjectContext = self.managedObjectContext;
    }
    else {
     */
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        //GeoSplitViewController *controller = [[GeoSplitViewController alloc] initWithNibName:@"GeoSplitViewController" bundle:nil];
        //GeoSplitTableController *tableView = [[GeoSplitTableController alloc] init];
        //JournalEntryViewController *child = [[JournalEntryViewController alloc] initWithNibName:@"JournalEntryView" bundle:nil];
        //UITableViewController *child = [[UITableViewController alloc] init];
        //controller.tableView = tableView;
        
        //controller.delegate = tableView;
        //controller.viewControllers = [NSArray arrayWithObjects:tableView, child, nil];
        [window addSubview:padMainController.view];
        //[window makeKeyAndVisible];
        //[controller release];
      
    }
    /*
    if (([[GeoDefaults sharedGeoDefaultsInstance].defaultInitDone intValue] == 0) ||
        ([[GeoDefaults sharedGeoDefaultsInstance].isPrivate intValue] == 1)) {

        _passCode = [[GeoDefaults sharedGeoDefaultsInstance] getPasscode];
        TRACE("%s, password: %d\n", __func__, _passCode);
        
        // This is first run, set up password
        //[self openPasscodeController];
        
    }
     */
    else {
        [self startTabBarView];
    }
    // Check the cloud sync.
    [self checkInSyncWithCloud];
    [GeoDatabase sharedGeoDatabaseInstance];

#if 0
    dispatch_async(dispatch_get_current_queue(), ^{
        /*
        NSMetadataQuery *metadataSearch = [[NSMetadataQuery alloc] init];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K like %@", NSMetadataItemFSNameKey, @"*"];
        [metadataSearch setPredicate:predicate];
        
        // Register the notifications for batch and completion updates
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(queryDidUpdate:)
                                                     name:NSMetadataQueryDidUpdateNotification
                                                   object:metadataSearch];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(initalGatherComplete:)
                                                     name:NSMetadataQueryDidFinishGatheringNotification
                                                   object:metadataSearch];
        
        // Set the search scope. In this case it will search the User's home directory
        // and the iCloud documents area
        NSArray *searchScopes;
        searchScopes=[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope,nil];
        [metadataSearch setSearchScopes:searchScopes];
        
        TRACE("%s, metasearch query: %p\n", __func__, metadataSearch);
        [metadataSearch startQuery];
         */
        //[self searchInCloud:@"*"];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        CloudFileService *service = [[CloudFileService alloc] init];
        NSURL *u = [NSURL fileURLWithPath:service.coreDataCloudContent isDirectory:YES];
        NSLog(@"url: %@, %@", u, service.coreDataCloudContent);
        NSArray *files = [fm contentsOfDirectoryAtURL:u
                                                       includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsRegularFileKey, nil] 
                                                                          options:NSDirectoryEnumerationSkipsHiddenFiles 
                                                                            error:&error];
        TRACE("%s, file count: %d\n", __func__, [files count]);

        NSNumber *aBool = nil;
        NSNumber *isDownloaded = nil;
        NSString *fileName = nil;
        for (NSURL *f in files) {
            [f getResourceValue:&aBool forKey:NSURLIsDirectoryKey error:&error];
            if (aBool && ![aBool boolValue]) {
                [f getResourceValue:&isDownloaded forKey:NSURLUbiquitousItemIsDownloadedKey error:&error];
                [f getResourceValue:&fileName forKey:NSURLNameKey error:&error];
                NSLog(@"file: %@, downloaded: %d, %@", f, [isDownloaded boolValue], fileName);
                
                if (isDownloaded != nil) {
                    if (![isDownloaded boolValue]) {
                        if ([[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:f error:&error] == NO) {
                            NSLog(@"faile to download: %@", error);
                        }
                        
                    }
                    else {
                        NSString *localFile = [service.documentDirectory stringByAppendingPathComponent:fileName];
                        TRACE("%s\n", [localFile UTF8String]);
                        if ([fm copyItemAtURL:f toURL:[NSURL fileURLWithPath:localFile] error:&error] == NO) {
                            NSLog(@"fail to copy: %@", error);
                        }
                    }
                }
            }
        }
         
        
    });
#endif
    //[[CloudService sharedCloudServiceInstance] start];
    //}
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
        //[self openPasscodeController];
    }
}

- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end

