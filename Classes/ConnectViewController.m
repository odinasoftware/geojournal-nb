//
//  ConnectViewController.m
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "ConnectViewController.h"
#import "AddMailRecipientController.h"
#import "GeoSession.h"
#import "FBConnect.h"
#import "GeoJournalHeaders.h"
#import "GeoDatabase.h"
#import "FacebookConnect.h"
#import "GeoDefaults.h"
#import "PTPasscodeViewController.h"
#import "KeychainItemWrapper.h"

#define CONNECT_SECTIONS	3
#define MAIL_INDEX			0
#define FACEBOOK_INDEX		1
#define CLOUD_INDEX         2
#define PASSCODE_INDEX      3

#define kConnectObjectKey	@"object"
#define kConnectHeaderKey	@"header"
#define kConnectFooterKey	@"footer"
#define kConnectRowsKey		@"rows"

#define kSwitchButtonWidth		94.0
#define kSwitchButtonHeight		27.0
#define kSwitchButtonXOffset    10.0
#define kSwitchButton1XOffset    10.0

NSString *kDisplaySwitchCell_ID = @"SwitchCell_ID";
NSString *kDisplaySwitchCell1_ID = @"PassCodeCell1_ID";
NSString *kDisplayDateCell_ID = @"DisplayDateCell_ID";
NSString *kSourceCell_ID = @"SourceCell_ID";

extern Boolean testReachability();

@implementation ConnectViewController

@synthesize _tableView;
@synthesize connectObjectArray;
@synthesize switchCtrl;
@synthesize cloudCtrl;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
	}
    return self;
}


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	TRACE_HERE;
    [super viewDidLoad];
	
	NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"ConnectTarget" ofType:@"plist"];
	connectObjectArray = [[NSArray alloc] initWithContentsOfFile:thePath];

    CGRect frame = CGRectMake(0.0, 0.0, kSwitchButtonWidth, kSwitchButtonHeight);
    UISwitch *s = [[UISwitch alloc] initWithFrame:frame];
    self.switchCtrl = s;
    [self.switchCtrl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    [s release];
    
    s = [[UISwitch alloc] initWithFrame:frame];
    self.cloudCtrl = s;
    [self.cloudCtrl addTarget:self action:@selector(cloudAction:) forControlEvents:UIControlEventValueChanged];
    [s release];
    
	self.tabBarController.tabBar.selectedItem.title = @"Connect";
	self.navigationItem.title = @"Connect";
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	TRACE_HERE;
	return [connectObjectArray count];
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// TODO: Get the default category and categories from database
	// Define NSArray for default category and fetch from database rest.
	TRACE_HERE;
	NSDictionary *dict = [connectObjectArray objectAtIndex:section];
	NSNumber *c = (NSNumber*)[dict objectForKey:kConnectRowsKey];
	return [c intValue];
}

/*
In tableView:didSelectRowAtIndexPath: you should always deselect the currently selected row.
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == MAIL_INDEX) {
		AddMailRecipientController *controller = [[AddMailRecipientController alloc] initWithNibName:@"AddMailRecipient" bundle:nil];
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else if (indexPath.section == FACEBOOK_INDEX) {
		if (testReachability() == false) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook Connect Warning" message:@"Internet connection is not available. We cannot connect to Facebook. Please check your Internet connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
		else {

			if ([GeoSession sharedGeoSessionInstance].fbUID > 0 /*&& [GeoSession sharedGeoSessionInstance].fbUserName*/) {
				// already logged in. prompt to logout.
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook logout" message:@"Do you want to logout from your Facebook account?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
				[alert show];
				[alert release];
			}
			else {
				[[GeoSession sharedGeoSessionInstance] getExtendedPermission:nil];
			}
		}
	}
	else {
		NSLog(@"%s, index error.", __func__);
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// TODO: need to define table cells.
	
	NSString* identity = nil; 
	UITableViewCell* cell = nil;
	
	TRACE("%s\n", __func__);
    if (indexPath.section == MAIL_INDEX || indexPath.section == FACEBOOK_INDEX) {
        identity = @"ConnectCell";
        [tableView dequeueReusableCellWithIdentifier:identity];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity] autorelease];
        }
    }
    else {
        identity = @"SwitchCtrlCell";
        [tableView dequeueReusableCellWithIdentifier:identity];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity] autorelease];
        }
    }
	
	if (indexPath.section == MAIL_INDEX) {
		NSDictionary *dict = [connectObjectArray objectAtIndex:indexPath.section];
		NSString *objectName = [dict objectForKey:kConnectObjectKey];
		NSString *r = [GeoDatabase sharedGeoDatabaseInstance].defaultRecipient;
		if (r) {
			NSString *format = [[NSString alloc] initWithFormat:@"%@", r];
			cell.textLabel.text = format;
			[format release];
		}
		else if ([[GeoDatabase sharedGeoDatabaseInstance].mailRecipientArray count] == 0) {
			NSString *format = [[NSString alloc] initWithFormat:@"%@ (No recipient setup)", objectName];
			cell.textLabel.text = format;
			[format release];
		}
		else {
			NSString *format = [[NSString alloc] initWithFormat:@"%@ (No default recipient set)", objectName];
			cell.textLabel.text = format;
			[format release];
		}

		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if (indexPath.section == FACEBOOK_INDEX) {
		NSDictionary *dict = [connectObjectArray objectAtIndex:indexPath.section];
		NSString *objectName = [dict objectForKey:kConnectObjectKey];

		if ([GeoSession sharedGeoSessionInstance].fbUserName) {
			NSString *format = [[NSString alloc] initWithFormat:@"%@ (%@)", objectName, [GeoSession sharedGeoSessionInstance].fbUserName];
			cell.textLabel.text = format;
			[format release];
		}
		else if ([GeoSession sharedGeoSessionInstance].fbUID && [[GeoSession sharedGeoSessionInstance].facebook isSessionValid]) {
			NSString *format = [[NSString alloc] initWithFormat:@"%@ (Logged in)", objectName];
			cell.textLabel.text = format;
			[format release];
		}
		else {
			NSString *format = [[NSString alloc] initWithFormat:@"%@ (User is not logged in)", objectName];
			cell.textLabel.text = format;
			[format release];
		}

		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    else if (indexPath.section == CLOUD_INDEX) {
        if ([indexPath row] == 0)
        {
                       
            // this cell hosts the UISwitch control
            cell.textLabel.text = @"iCloud:";
            CGRect bound = cell.contentView.bounds;
            DEBUG_RECT("cloud bound:", bound);
            float x = bound.size.width-kSwitchButtonWidth-kSwitchButtonXOffset;
            float y = (bound.size.height-kSwitchButtonHeight)/2;
            TRACE("%s, x: %f, y: %f\n", __func__,x, y);
            self.cloudCtrl.on = [[GeoDefaults sharedGeoDefaultsInstance].enableCloud boolValue];
            self.cloudCtrl.frame = CGRectMake(x, y, kSwitchButtonWidth, kSwitchButtonHeight);
            DEBUG_RECT("cloud: ", self.cloudCtrl.frame);
            [cell.contentView addSubview:self.cloudCtrl];
        }
        
    }

    else if (indexPath.section == PASSCODE_INDEX) {
        if ([indexPath row] == 0)
        {
          
            // this cell hosts the UISwitch control
            cell.textLabel.text = @"Passcode:";
            CGRect bound = cell.contentView.bounds;
            DEBUG_RECT("content bound:", bound);
            float x = bound.size.width-kSwitchButtonWidth-kSwitchButtonXOffset;
            float y = (bound.size.height-kSwitchButtonHeight)/2;
            TRACE("%s, x: %f, y: %f\n", __func__,x, y);
            self.switchCtrl.on = [[GeoDefaults sharedGeoDefaultsInstance].isPrivate boolValue];
            self.switchCtrl.frame = CGRectMake(x, y, kSwitchButtonWidth, kSwitchButtonHeight);
            DEBUG_RECT("switch: ", self.switchCtrl.frame);
            [cell.contentView addSubview:self.switchCtrl];
       }
       
    }
	else {
		NSLog(@"%s, index error: %d", __func__, indexPath.row);
	}
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSDictionary *dict = [connectObjectArray objectAtIndex:section];
	NSString *header = (NSString*) [dict objectForKey:kConnectHeaderKey];
	return header;
}
		
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	NSDictionary *dict = [connectObjectArray objectAtIndex:section];
	NSString *footer = (NSString*) [dict objectForKey:kConnectFooterKey];
	return footer;	
}

- (void)switchAction:(id)sender
{
    NSNumber *n = [[NSNumber alloc] initWithInt:self.switchCtrl.on];
    [GeoDefaults sharedGeoDefaultsInstance].isPrivate = n;
    [n release];
    
    if (self.switchCtrl.on) {
        // Ask password
        PTPasscodeViewController *passcodeViewController = [[PTPasscodeViewController alloc] initWithDelegate:self passcode:NO];
        [self.navigationController pushViewController:passcodeViewController animated:YES];
    }

}

- (void)cloudAction:(id)sender
{
    NSNumber *n = [[NSNumber alloc] initWithInt:self.cloudCtrl.on];
    [GeoDefaults sharedGeoDefaultsInstance].enableCloud = n;
    [n release];
    
    // TODO: enable cloud action 
    
}
#pragma mark CALLBACK_API
- (void)fbUserDidLogin
{
	TRACE("%s\n", __func__);
	[self._tableView reloadData];
}

#pragma mark -

#pragma mark ALERTVIEW delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0:
			break;
		case 1:
			[[GeoSession sharedGeoSessionInstance] logoutFBSessionWithNotification:YES];
			break;
		case 2:
			
			break;
		default:
			NSLog(@"%s, index error: %d", __func__, buttonIndex);
	}
}

#pragma mark -
#pragma PTPasscode
- (void) didShowPasscodePanel:(PTPasscodeViewController *)passcodeViewController panelView:(UIView*)panelView
{
    TRACE_HERE;
    [passcodeViewController setTitle:@"Set Passcode"];
    // Please enter your passcode to log on
    // Incorrect passcode. Try again.
    if([panelView tag] == kPasscodePanelOne) {
        [[passcodeViewController titleLabel] setText:@"Enter a passcode"];
    }
    
    if([panelView tag] == kPasscodePanelTwo) {
        [[passcodeViewController titleLabel] setText:@"Re-enter your passcode"];
    }
    
    if([panelView tag] == kPasscodePanelThree) {
        [[passcodeViewController titleLabel] setText:@"Re-enter your passcode"];
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
    BOOL savePassword = NO;
    NSLog(@"END PASSCODE - %d", passCode);
    
    if([panelView tag] == kPasscodePanelOne) {
        _passCode = passCode;
        
        
        /*if(_passCode != passCode) {
         [[passcodeViewController summaryLabel] setText:@"Invalid PIN code"];
         [[passcodeViewController summaryLabel] setTextColor:[UIColor redColor]];
         [passcodeViewController clearPanel];
         return FALSE;
         }*/
        
        return ![passcodeViewController nextPanel];
    }
    
    if([panelView tag] == kPasscodePanelTwo) {
        _retryPassCode = passCode;
        
        if(_retryPassCode != _passCode) {
            [passcodeViewController nextPanel];
            [[passcodeViewController summaryLabel] setText:@"Passcode did not match. Try again."];
            return FALSE;
        } else {
            savePassword = YES;
        }
        
    }
    else if ([panelView tag] == kPasscodePanelThree) {
        _retryPassCode = passCode;
        
        if(_retryPassCode != _passCode) {
            NSNumber *n = [[NSNumber alloc] initWithInt:NO];
            [GeoDefaults sharedGeoDefaultsInstance].isPrivate = n;
            [n release];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Set Passcode" message:@"Passcode did not match. Can't set passcode!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [self.navigationController popViewControllerAnimated:YES];
            
            return FALSE;
        } else {
            //[[passcodeViewController summaryLabel] setText:@"Good boy !"];    
            savePassword = YES;
        }

    }
    
    if (savePassword) {
        [[GeoDefaults sharedGeoDefaultsInstance] setPasscode:_passCode];
        [self.navigationController popViewControllerAnimated:YES];
        TRACE("%s, save passcode: %d\n", __func__, _passCode);
        
    }
    //  return ![passcodeView nextPanel];
    
    return TRUE;
}

#pragma -
#pragma mark GENERAL


#pragma mark -
#pragma mark MEMORY MANAGEMENT
- (void)didReceiveMemoryWarning {
	TRACE_HERE;
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	TRACE_HERE;
	self.connectObjectArray = nil;
	self._tableView = nil;
    self.switchCtrl = nil;
    self.cloudCtrl = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    TRACE_HERE;
	[self._tableView reloadData];
}

- (void)dealloc {
	TRACE_HERE;
	[_tableView release];
	[connectObjectArray release];
    [switchCtrl release];
    [cloudCtrl release];
	
    [super dealloc];
}


@end
