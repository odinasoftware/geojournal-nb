//
//  GeoTakeController.m
//  GeoJournal
//
//  Created by Jae Han on 5/27/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <MapKit/MKAnnotationView.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "GeoTakeController.h"
#import "SpeakHereController.h"
#import "GeoJournalHeaders.h"
#import "GeoMark.h"
#import "CommonObject.h"
#import "GeoDefaults.h"
#import "Journal.h"
#import "GeoDatabase.h"
#import "TextInputController.h"
#import "CameraThread.h"

#define PICTURE_X			15.0
#define PICTURE_Y			18.0
#define PICTURE_WIDTH		288.0
#define PICTURE_HEIGHT		216.0
#define MAX_TITLE_LEN		50

#define LANDSCAPE_X			15.0
#define LANDSCAPE_Y			50.0
#define PORTRAIT_X			50.0
#define PORTRAIT_Y			10.0

#define INSIDE_VIEW_X		0.0
#define INSIDE_VIEW_Y		45.0
#define INSIDE_VIEW_WIDTH	320.0
#define INSIDE_VIEW_HEIGHT	327.0

#define BACKGROUND_X		12.0
#define BACKGROUND_Y		17.0
#define BACKGROUND_X2		15.0
#define BACKGROUND_Y2		15.0
#define BACKGROUND_WIDTH	25.0
#define BACKGROUND_HEIGHT	35.0
#define BACKGROUND_WIDTH2	30.0
#define BACKGROUND_HEIGHT2	30.0


#define LANDSCAPE_WIDTH		288.0
#define LANDSCAPE_HEIGHT	216.0
#define PORTRAIT_WIDTH		225.0
#define PORTRAIT_HEIGHT		300.0

#define MIN_TITLE_LEN		25
#define COORD_DIFF			0.00005
#define DESIRED_ACCURACY	100.0
#define STOP_COUNT			3
#define	MAX_LOCATION_RECEPTION_COUNT	24

extern "C" {
	NSString *getTitle(NSString *content) {
		NSString *title = nil;
		NSCharacterSet *set = [NSCharacterSet newlineCharacterSet];
		
		NSInteger length = ([content length]>MAX_TITLE_LEN?MAX_TITLE_LEN:[content length]);
		NSRange end = [content rangeOfCharacterFromSet:set options:NSCaseInsensitiveSearch range:NSMakeRange(0, length)];
		
		
		if (end.location != NSNotFound) {
			title = [content substringToIndex:end.location];
		}
		else if (length > MIN_TITLE_LEN) {
			title = [NSString stringWithFormat:@"%@...", [content substringToIndex:MIN_TITLE_LEN]];
		}
		else {
			title = [NSString stringWithString:content];
		}
		
		
		TRACE("%s, %s", __func__, [title UTF8String]);
		return title;
	}
	
	Boolean testReachability()
	{
		Boolean success;
		Boolean isDataSourceAvailable;
		
		const char* host_name = "www.apple.com";
		
		SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host_name);
		SCNetworkReachabilityFlags flags;
		
		success = SCNetworkReachabilityGetFlags(reachability, &flags);
		
		isDataSourceAvailable = success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);
		
		CFRelease(reachability);
		
		NSLog(@"%s, %d, 0x%x, available: %d", __func__, success, flags, isDataSourceAvailable);
		
		return isDataSourceAvailable;
	}
	
	CLLocationAccuracy geoNextAccuracy(CLLocationAccuracy current) {
		CLLocationAccuracy next = current;
		
		if (current == kCLLocationAccuracyBest) {
			next = kCLLocationAccuracyNearestTenMeters;
		}
		else if (current == kCLLocationAccuracyHundredMeters) {
			next = kCLLocationAccuracyNearestTenMeters;
		}
		else if (current == kCLLocationAccuracyNearestTenMeters) {
			next = kCLLocationAccuracyNearestTenMeters;
		}
		else {
			next = kCLLocationAccuracyBest;
		}
		
		TRACE("%s, current: %f, new: %f\n", __func__, current, next);
		return next;
	}
	
	UIImage *getReducedImage(UIImage *image, float ratio) {
		UIImage *newImage = nil;
		
		CGSize newSize = CGSizeMake(image.size.width/ratio, image.size.height/ratio);
		UIGraphicsBeginImageContext(newSize);
		[image drawInRect:CGRectMake(0.0, 0.0, newSize.width, newSize.height)];
		newImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		//newImage = [UIImage imageWithCGImage:image.CGImage scale:ratio orientation:UIImageOrientationUp];
		
		TRACE("%s, orientation: %d, ratio: %f, width: %f, height: %f\n", __func__, image.imageOrientation, ratio, newImage.size.width, newImage.size.width);
		return newImage;
	}
	
}





@implementation GeoTakeController

@synthesize titleMapAccuracy;
@synthesize precisionForMap;
@synthesize myTitle;
@synthesize backgroundImage;
@synthesize titleForJournal;
@synthesize textBackground;
@synthesize mapButton;
@synthesize pictureButton;
@synthesize noteButton;
@synthesize voiceButton;
@synthesize toolBar;
@synthesize insideView;
@synthesize textView;
//@synthesize lvlMeter_in;
@synthesize pictureView;
@synthesize mapView;
//@synthesize secondTimer;

@synthesize onImage, offImage, locateImage;
@synthesize locationManager, cameraController;
@synthesize myAudio, myPicture, myNote, myLocation;
@synthesize audioController;
@synthesize selectedCategory;
@synthesize location;
@synthesize journalTaken;
@synthesize pictureTakenImage;
@synthesize thumbnailImage;
@synthesize geoCoder;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		bButtonMapOn = YES;
		bButtonPictureOn = NO;
		bButtonNoteOn = NO;
		
		self.onImage = [UIImage imageNamed:@"OnButton.png"];
		// If we don't retain it, it will be crashed when the view is unloaded and loaded again.
		self.locateImage = [UIImage imageNamed:@"locate.png"];
		
		pictureTakenImage = nil;
		offImage = nil;
		//CLLocationManager *manager = [[CLLocationManager alloc] init];
		//self.locationManager = manager;
		//locationManager.delegate=self;
		//locationManager.desiredAccuracy=kCLLocationAccuracyThreeKilometers; //kCLLocationAccuracyHundredMeters; //kCLLocationAccuracyNearestTenMeters;
		//[manager release];
		desiredAccuracy = kCLLocationAccuracyThreeKilometers;
		
		//calendar= [CommonObject sharedCommonObjectInstance].calendar;//[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		// Init for camera controller
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
			cameraController = [[UIImagePickerController alloc] init];
			cameraController.delegate = self;
			cameraController.sourceType = UIImagePickerControllerSourceTypeCamera;
		}
		else {
			cameraController = nil;
		}		
		
		geoCurrentStatus = GEO_MAP;
		
		myAudio = myNote = myPicture = myLocation = nil;
		location = nil;
		self.geoCoder = nil;
		isLocationUpdating = NO;
		updateCount = 0;
		locationClickCount = 0;
		addPlaceMarkCount = 0;
		stopCount = STOP_COUNT;
    }
    return self;
}


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
// TODO: view can be unloaded. 
- (void)viewDidLoad {
	TRACE_HERE;
    [super viewDidLoad];
	
	UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"notloaded.png"]];
	self.backgroundImage = image;
	[image release];
	
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
									 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
	
	//self.navigationItem.prompt = @"Select article sections";
	self.navigationItem.leftBarButtonItem = cancelButton;
	[cancelButton release];
	
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
								   initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = doneButton;
	[doneButton release];
	
	// change color of tool bar at the bottom.
	//self.toolBar.tintColor = [UIColor colorWithRed:0.3983 green:0.3081 blue:0.3598 alpha:1.0]; // green pattern
	//self.toolBar.tintColor = [UIColor colorWithRed:0.8010 green:0.0388 blue:0.1291 alpha:1.0]; // red pattern
	//self.toolBar.tintColor = [UIColor blackColor];
	self.toolBar.tintColor = [UIColor colorWithRed:0.1757 green:0.0752 blue:0.2928 alpha:1.0]; // 
	
	//self.toolBar.tintColor = [UIColor colorWithRed:0.0235 green:0.3137 blue:0.1765 alpha:1.0]; // 
	//self.toolBar.tintColor = [UIColor colorWithRed:0.1961 green:0.2784 blue:0.0157 alpha:1.0]; // 
	//self.toolBar.tintColor = [UIColor colorWithRed:0.1647 green:0.2902 blue:0.1373 alpha:1.0]; // 
	
	self.navigationItem.title = self.titleForJournal;
	
	[self startView:geoCurrentStatus];
	[self registerForKeyboardNotifications];
	self.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	keyboardShown = NO;
	journalTaken = JOURNAL_NONE;
}

#pragma mark COMMON

- (void)closeAudioPlayer
{
	[audioController closeAudioPlayer];
}

- (void) startView:(GeoCurrentStatusType)mode
{
	switch (mode) {
		case GEO_MAP:
			[self toggleButtonMap:nil];
			//[self startMapView];
			break;
		case GEO_CAMERA:
			[self toggleButtonPicture:nil];
			//[self startCameraView];
			break;
		case GEO_NOTE:
			[self toggleButtonNote:nil];
			//[self startNoteView];
			break;
		case GEO_RECORD:
			[self toggleButtonVoice:nil];
			//[self startAudioView];
			break;
		default:
			NSLog(@"%s, undefined mode: %d", __func__, mode);
	}
}

- (void) cleanView:(GeoCurrentStatusType)mode 
{
	switch (mode) {
		case GEO_MAP:
			[self clearMapView];
		case GEO_CAMERA:
		case GEO_NOTE:
			break;
		case GEO_RECORD:
			[self cleanRecordView];
			break;
		default:
			NSLog(@"%s, undefined mode: %d", __func__, mode);
	}
}
// TODO: Track the current status and clean up when the status switch to other one.

- (IBAction)toggleButtonMap:(id)sender
{
	if (geoCurrentStatus == GEO_NOTE && keyboardShown == YES)
		return;
	
	GeoCurrentStatusType prevStatus = geoCurrentStatus;
	geoCurrentStatus = GEO_MAP;
	if (prevStatus != geoCurrentStatus)
		[self cleanView:prevStatus];
	
	[mapButton setBackgroundImage:onImage forState:UIControlStateNormal];
	[mapButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	
	[pictureButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[pictureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	[noteButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[noteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	[voiceButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[voiceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

	[self startMapView];
}

- (IBAction)toggleButtonPicture:(id)sender
{
	if (geoCurrentStatus == GEO_NOTE && keyboardShown == YES)
		return;
	
	GeoCurrentStatusType prevStatus = geoCurrentStatus;
	geoCurrentStatus = GEO_CAMERA;
	if (prevStatus != geoCurrentStatus)
		[self cleanView:prevStatus];
	
	[pictureButton setBackgroundImage:onImage forState:UIControlStateNormal];
	[pictureButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	
	[mapButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[mapButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	[noteButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[noteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	[voiceButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[voiceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	[self startCameraView];
}

- (IBAction)toggleButtonNote:(id)sender
{
	if (geoCurrentStatus == GEO_NOTE && keyboardShown == YES)
		return;
	
	GeoCurrentStatusType prevStatus = geoCurrentStatus;
	geoCurrentStatus = GEO_NOTE;
	if (prevStatus != geoCurrentStatus)
		[self cleanView:prevStatus];
	
	[noteButton setBackgroundImage:onImage forState:UIControlStateNormal];
	[noteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	
	[mapButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[mapButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	[pictureButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[pictureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	[voiceButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[voiceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	[self startNoteView];
}

- (IBAction)toggleButtonVoice:(id)sender
{
	if (geoCurrentStatus == GEO_NOTE && keyboardShown == YES)
		return;
	
	GeoCurrentStatusType prevStatus = geoCurrentStatus;
	geoCurrentStatus = GEO_RECORD;
	if (prevStatus != geoCurrentStatus)
		[self cleanView:prevStatus];
	
	[voiceButton setBackgroundImage:onImage forState:UIControlStateNormal];
	[voiceButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	
	[noteButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[noteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	[mapButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[mapButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	[pictureButton setBackgroundImage:offImage forState:UIControlStateNormal];
	[pictureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	[self startAudioView];
}

#pragma mark NoteController

- (void)startNoteView
{
	[self removeSubviews];
	
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:@selector(retake:)];
	NSArray *items = [NSArray arrayWithObject:item];
	[self.toolBar setItems:items];
	[item release];
	
	TRACE("%s, note: %s, %s\n", __func__, [self.myNote UTF8String], [self.textView.text UTF8String]);
	if (self.myNote && (self.textView.text == nil || [self.textView.text length] == 0)) {
		self.textView.text = self.myNote;
	}
	else {
		self.myTitle = getTitle(textView.text);
		self.myNote = textView.text;
	}

	
	[self.insideView addSubview:textBackground];
	[self.insideView addSubview:textView];
	
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasShown:)
												 name:UIKeyboardDidShowNotification object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasHidden:)
												 name:UIKeyboardDidHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
	TRACE_HERE;
    if (keyboardShown)
       return;
	
    NSDictionary* info = [aNotification userInfo];
	
    // Get the size of the keyboard.
    NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
	NSTimeInterval animationDuration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    // Resize the scroll view (which is the root view of the window)
    CGRect viewFrame = CGRectMake(INSIDE_VIEW_X, INSIDE_VIEW_Y, INSIDE_VIEW_WIDTH, INSIDE_VIEW_HEIGHT);
    viewFrame.size.height -= keyboardSize.height;
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
   
    TRACE("%s, %f\n", __func__, viewFrame.size.height);
    self.insideView.frame = viewFrame; 
	[UIView commitAnimations];
    // Scroll the active text field into view.
    //CGRect textFieldRect = [textView frame];
    //[self.insideView scrollRectToVisible:textFieldRect animated:YES];
	
    keyboardShown = YES;
}


// Called when the UIKeyboardDidHideNotification is sent
- (void)keyboardWasHidden:(NSNotification*)aNotification
{
	TRACE_HERE;
    NSDictionary* info = [aNotification userInfo];
	
    // Get the size of the keyboard.
    NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
	
    // Reset the height of the scroll view to its original value
    CGRect viewFrame = CGRectMake(INSIDE_VIEW_X, INSIDE_VIEW_Y, INSIDE_VIEW_WIDTH, INSIDE_VIEW_HEIGHT);
    //viewFrame.size.height += keyboardSize.height;
    self.insideView.frame = viewFrame;
	
	TRACE("%s, %f\n", __func__, viewFrame.size.height);
    keyboardShown = NO;
}


#pragma mark CameraController

// TODO: view can be unloaded anytime after UIImagePicker controller for camera is activated. 
//       After taking a picture, view is crashing. 

- (void)startCameraView
{
	[self removeSubviews];
	
	UIBarButtonItem	*retake = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(retake:)];
	UIBarButtonItem	*space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem	*fromLibrary = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(getPictureFromLibrary:)];
	
	NSArray *items = [NSArray arrayWithObjects:retake, space, fromLibrary, nil];
	[self.toolBar setItems:items];
	[retake release]; 
	
	[self.insideView addSubview:self.backgroundImage];
	
	if (self.pictureView == nil) {
		CGRect frame = CGRectMake(PICTURE_X, PICTURE_Y, PICTURE_WIDTH, PICTURE_HEIGHT);
		UIImageView *iv = [[UIImageView alloc] initWithFrame:frame];
	
		self.pictureView = iv;
		[iv release];
	}
	TRACE("%s, %p, %p\n", __func__, self.pictureView, self.pictureView.image);
	if (self.pictureTakenImage != nil) {
		//if (pictureView.image != nil && pictureView.image != self.pictureTakenImage) {
		//	[pictureView.image release];
		//}
		if (self.pictureTakenImage.size.width > self.pictureTakenImage.size.height) {
			// Landscape
			pictureView.frame = CGRectMake(LANDSCAPE_X, LANDSCAPE_Y, LANDSCAPE_WIDTH, LANDSCAPE_HEIGHT);
			backgroundImage.frame = CGRectMake(LANDSCAPE_X - BACKGROUND_X2, LANDSCAPE_Y - BACKGROUND_Y2, LANDSCAPE_WIDTH+BACKGROUND_WIDTH2, LANDSCAPE_HEIGHT+BACKGROUND_HEIGHT2);
		}
		else {
			// portrait
			pictureView.frame = CGRectMake(PORTRAIT_X, PORTRAIT_Y, PORTRAIT_WIDTH, PORTRAIT_HEIGHT);
			backgroundImage.frame = CGRectMake(PORTRAIT_X - BACKGROUND_X, PORTRAIT_Y - BACKGROUND_Y, PORTRAIT_WIDTH+BACKGROUND_WIDTH, PORTRAIT_HEIGHT+BACKGROUND_HEIGHT);
			
		}
		
		self.pictureView.image = self.pictureTakenImage;
		[self.insideView addSubview:pictureView];
	}
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
	[picker dismissModalViewControllerAnimated:TRUE];
	[self.insideView addSubview:pictureView];
	
	// TODO: Possible API -> UIImageWriteToSavedPhotosAlbum
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	
	self.pictureTakenImage = getReducedImage(image, REDUCE_RATIO);
	self.thumbnailImage = getReducedImage(image, THUMBNAIL_RATIO);
	
	pictureView.image = self.pictureTakenImage;
	
	/*
	float x, y, move_x, move_y;
	GET_COORD_IN_PROPORTION(pictureView.frame.size, pictureView.image, &x, &y);
	move_x = MAKE_CENTER(x - pictureView.frame.size.width);
	move_y = MAKE_CENTER(y - pictureView.frame.size.height);
	
	//float move = (articleImageView.frame.size.width > x ? (articleImageView.frame.size.width - x)/2.0:0.0);
	backgroundImage.frame = CGRectMake(pictureView.frame.origin.x+move_x-BACKGROUND_X, pictureView.frame.origin.y+move_y-BACKGROUND_Y, x+BACKGROUND_WIDTH, y+BACKGROUND_HEIGHT);
	pictureView.frame = CGRectMake(pictureView.frame.origin.x+move_x, pictureView.frame.origin.y+move_y, x, y);
	*/
	
	if (self.pictureTakenImage.size.width > self.pictureTakenImage.size.height) {
		// Landscape
		pictureView.frame = CGRectMake(LANDSCAPE_X, LANDSCAPE_Y, LANDSCAPE_WIDTH, LANDSCAPE_HEIGHT);
		backgroundImage.frame = CGRectMake(LANDSCAPE_X - BACKGROUND_X2, LANDSCAPE_Y - BACKGROUND_Y2, LANDSCAPE_WIDTH+BACKGROUND_WIDTH2, LANDSCAPE_HEIGHT+BACKGROUND_HEIGHT2);
	}
	else {
		// portrait
		pictureView.frame = CGRectMake(PORTRAIT_X, PORTRAIT_Y, PORTRAIT_WIDTH, PORTRAIT_HEIGHT);
		backgroundImage.frame = CGRectMake(PORTRAIT_X - BACKGROUND_X, PORTRAIT_Y - BACKGROUND_Y, PORTRAIT_WIDTH+BACKGROUND_WIDTH, PORTRAIT_HEIGHT+BACKGROUND_HEIGHT);

	}
	
	TRACE("%s, c: %d\n", __func__, [pictureView.image retainCount]);
	
	
	self.myPicture = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:GEO_IMAGE_EXT];
	DEBUG_RECT("picture", pictureView.frame);
	DEBUG_RECT("background", backgroundImage.frame);
	// Move to parent controller because of taking too much of time.
	//saveImageToFile(image, self.myPicture);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[picker dismissModalViewControllerAnimated:TRUE];
}

- (void)retake:(id)sender
{
	//[[CameraThread sharedCameraControllerInstance] startCameraView:self withPicker:self.cameraController];
	if (cameraController) 
		[self presentModalViewController:cameraController animated:YES];
}

- (void)getPictureFromLibrary:(id)sender
{
	UIImagePickerController *controller = [[UIImagePickerController alloc] init];
	controller.delegate = self;
	controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary; //UIImagePickerControllerSourceTypePhotoLibrary | UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	
	[self presentModalViewController:controller animated:YES];
}

#pragma mark AudioController

- (void)startAudioView
{
	[self removeSubviews];
	
	NSArray *items = [NSArray arrayWithObjects:nil];
	[self.toolBar setItems:items];
	
	if (self.audioController == nil) {
		SpeakHereController *c = [[SpeakHereController alloc] initWithNibName:@"AudioView" bundle:nil];
		self.audioController = c;
		[c release];
	}
	
	if (self.myAudio != nil) {
		[self.audioController prepareToPlay:self.myAudio];
	}
	
	// TODO: how to supply file name to the view.
	[audioController startTimer];
	[self.insideView addSubview:self.audioController.view];
}

- (void)cleanRecordView
{
	//[self.secondTimer invalidate];
	//self.secondTimer = nil;
	[audioController stopTimer];
	[audioController stopRecord];
	[audioController stopPlayQueue];
}

	
#pragma mark MapController
- (void)checkLocationUpdateStatus
{
	if ((isLocationUpdating == YES) &&
		(self.geoCoder == nil || self.myLocation == nil)) {
		// either haven't the location or the reverse location.
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location update warning" message:@"Your location information has not been completed. You may not have correct location information." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
		[self.locationManager stopUpdatingLocation];
		if (self.geoCoder)
			[self.geoCoder cancel];
	}
}

- (void)addLocationToMap:(CLLocation*)loc
{
	MKCoordinateRegion region;
	region.center=loc.coordinate;
	//Set Zoom level using Span
	MKCoordinateSpan span;
	span.latitudeDelta=.005;
	span.longitudeDelta=.005;
	region.span=span;
	
	GeoMark *park = [[GeoMark alloc] initWithCoordinate:loc.coordinate];
	[self.mapView addAnnotation:park];
	[self.mapView selectAnnotation:park	animated:NO];
	
	[self.mapView setRegion:region animated:NO];	
}

- (void)showMapAccuracyLabel:(CLLocation*)loc;
{
	UILabel *label = nil;
	UILabel *accuracy = nil;
	
	if (self.titleMapAccuracy == nil) {
		label = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 0.0, 200.0, 30.0)];
		label.text = @"Location accuracy";
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13];//[UIFont systemFontOfSize:12.0];
		label.textColor = [UIColor whiteColor];
	}
	
	if (self.precisionForMap == nil) {
		accuracy = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 12.0, 200.0, 30.0)];
		if (loc == nil) {
			accuracy.text = @"Not available";
		}
		else {
			accuracy.text = [NSString stringWithFormat:@"+/- %f", loc.horizontalAccuracy];
		}
		accuracy.backgroundColor = [UIColor clearColor];
		accuracy.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12];//[UIFont systemFontOfSize:12.0];
		accuracy.textColor = [UIColor whiteColor];		
	}
	else if (loc != nil) {
		self.precisionForMap.text = [NSString stringWithFormat:@"+/- %5.2fm", loc.horizontalAccuracy];
	}
	
	if (label) {
		[self.toolBar addSubview:label];
		self.titleMapAccuracy = label;
		[label release];
	}
	if (accuracy) {
		[self.toolBar addSubview:accuracy];
		self.precisionForMap = accuracy;
		[accuracy release];
	}
	
}

/*
 * MapView and location manager:
 *   locationManager: can activate by startUpdatingLocation.
 *   MKCoordinateRegion: set zoom level when a coordinate is available.
 *   TODO: how can we set a annotation mark?
 */
- (void)startMapView 
{
	[self removeSubviews];
	
	if (isLocationUpdating == TRUE) {
		[self showActivity];
	}
	else {
		[self showLocateMe];
	}
	
	
	if (self.location && self.myLocation && [self.mapView.annotations count] == 0) {
		[self addLocationToMap:self.location];
	}
	[self showMapAccuracyLabel:self.location];
	
	[self.insideView addSubview:self.mapView];	
}

- (void)showActivity
{
	UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	UIBarButtonItem *progress = [[UIBarButtonItem alloc] initWithCustomView:activityView];
	NSArray *items = [NSArray arrayWithObjects:progress, nil];
	[activityView startAnimating];
	[self.toolBar setItems:items];
	[activityView release];
	[progress release];
}

- (void)clearMapView
{
	//[self.titleMapAccuracy removeFromSuperview];
	//[self.precisionForMap removeFromSuperview];
}

- (void)showLocateMe
{
	
	if (geoCurrentStatus == GEO_MAP) {
		UIBarButtonItem *locateMe = [[UIBarButtonItem alloc] initWithImage:self.locateImage style:UIBarButtonItemStylePlain target:self action:@selector(locateUser:)];
		//UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
		//UIBarButtonItem *precision = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
		//UIBarButtonItem *flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		
		//flex.width = 100;
		//precision.enabled = NO;
			
		NSArray *items = [NSArray arrayWithObjects:locateMe, nil];
		[self.toolBar setItems:items];
		
		[self showMapAccuracyLabel:nil];
		
		
		//self.precisionForMap = precision;
		[locateMe release];
		
		//[precision release];
		//[flex release];
		//[flex1 release];
	}
		
}

- (void)locateUser:(id)sender
{
	/* to use a CLLocationManager object to deliver location events, create an instance, 
	 assign a delegate object to it, configure the desired accuracy and distance filter values, 
	 and call the startUpdatingLocation method. 
	 */
	if (testReachability() == false) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Map Warning" message:@"Internet connection is not available. Your location information will not be available. Please check your Internet connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	else {
		isLocationUpdating = TRUE;
		
		//locationManager.desiredAccuracy = geoNextAccuracy(locationManager.desiredAccuracy);
		if (self.locationManager && self.locationManager.location != nil) {
			// still some event is running, stop first.
			[locationManager stopUpdatingLocation];
			stopCount += STOP_COUNT;
		}
		CLLocationManager *manager = [[CLLocationManager alloc] init];
		self.locationManager = manager;
		self.locationManager.delegate = self;
		desiredAccuracy = geoNextAccuracy(desiredAccuracy);
		self.locationManager.desiredAccuracy = desiredAccuracy;
		[self.locationManager startUpdatingLocation];
		[manager release];
		locationClickCount++;
		[self showActivity];
		if (stopCount > MAX_LOCATION_RECEPTION_COUNT) {
			stopCount = MAX_LOCATION_RECEPTION_COUNT;
		}
		self.precisionForMap.text = @"Acquiring...";
	}
}

- (MKAnnotationView *) mapView:(MKMapView *)view viewForAnnotation:(id <MKAnnotation>) annotation{
	//MKAnnotationView *annView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"currentloc"];
	//annView.animatesDrop=TRUE;
	NSString *reuseIdentifier = @"GoeTakeCell";
	MKPinAnnotationView *annView = nil;
	
	annView = (MKPinAnnotationView*) [mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];
	if (annView == nil) {
		annView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
	}
	
	TRACE("%s: %p, %s", __func__, annView, [[annotation title] UTF8String]);
	annView.enabled = TRUE;
	annView.canShowCallout = YES;
	annView.animatesDrop = YES;
	[annView setPinColor:MKPinAnnotationColorRed];
	[annView setSelected:YES];
	
	return annView;
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error{
	NSLog(@"Reverse Geocoder Errored, %@", error);
	isLocationUpdating = NO;
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark{
	self.myLocation = [[NSString alloc] initWithFormat:@"%s, %s, %s", [[placemark locality] UTF8String],
																	[[placemark administrativeArea] UTF8String],
																	[[placemark countryCode] UTF8String]];
	TRACE("%s, %s\n", __func__, [self.myLocation UTF8String]);
	//mPlacemark=placemark;
	
	//[mapView addAnnotation:placemark];
	isLocationUpdating = NO;
	//[locationManager stopUpdatingLocation];
	[self showLocateMe];
}

/* 
 * didUpdateToLocation:
 *   TODO: 1. why is this called twice at least? Why sometimes getting called repeateably. <<-- 
 *         2. It can come from cached data, so it will need to get the timestamp too. 
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
	//mStoreLocationButton.hidden=FALSE;
	
	//One location is obtained.. just zoom to that location
	//TRACE("%s, lo: %f, la: %f\n", __func__, newLocation.coordinate.longitude, newLocation.coordinate.latitude);
	TRACE("%s, new: %s, old: %s\n", __func__, [[newLocation description] UTF8String], [[oldLocation description] UTF8String]);
	TRACE("s: %d, d: %f, h: %f, v: %f\n", stopCount, manager.desiredAccuracy, newLocation.horizontalAccuracy, newLocation.verticalAccuracy);

	//if (fabs(newLocation.coordinate.longitude - oldLocation.coordinate.longitude) < COORD_DIFF &&
	//	fabs(newLocation.coordinate.latitude - oldLocation.coordinate.latitude) < COORD_DIFF) {
	//if (newLocation.horizontalAccuracy <= self.locationManager.desiredAccuracy) {
	
	updateCount++;
	if (addPlaceMarkCount < locationClickCount &&
		(addPlaceMarkCount == 0 || 
		newLocation.horizontalAccuracy < desiredAccuracy ||
		updateCount >= stopCount)) {
		self.location=newLocation;
		MKCoordinateRegion region;
		region.center=location.coordinate;
		//Set Zoom level using Span
		MKCoordinateSpan span;
		span.latitudeDelta=.005;
		span.longitudeDelta=.005;
		region.span=span;
		
		if ([mapView.annotations count] > 0) {
			[mapView removeAnnotations:mapView.annotations];
		}
		GeoMark *park = [[GeoMark alloc] initWithCoordinate:location.coordinate];
		[mapView addAnnotation:park];
		[mapView selectAnnotation:park	animated:YES];
		[park release];
		
		MKReverseGeocoder *coder = [[MKReverseGeocoder alloc] initWithCoordinate:newLocation.coordinate];
		coder.delegate = self;
		self.geoCoder = coder;
		[self.geoCoder start];
		[coder release];
		
		[mapView setRegion:region animated:TRUE];
		addPlaceMarkCount++;
		
		if (updateCount >= stopCount) {
			// Stop updating
			[manager stopUpdatingLocation];
		}
		updateCount = 0;
		self.precisionForMap.text = [NSString stringWithFormat:@"+/- %5.2fm", newLocation.horizontalAccuracy];

	}	
	
		
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"%s, %@", __func__, error);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Map warning" message:@"Location update failed. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

#pragma mark Generic

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	TRACE("%s, %d\n", __func__, buttonIndex);
	switch (buttonIndex) {
		case 1:
			[self.geoCoder cancel];
			[self cleanView:geoCurrentStatus];
			[self.navigationController dismissModalViewControllerAnimated:YES];
			self.journalTaken = JOURNAL_CANCELLED;
			
			break;
		default:
			break;
	}
}

- (void)removeSubviews
{
	NSArray *subviews = self.insideView.subviews;
	
	for (UIView *view in subviews) {
		[view removeFromSuperview];
	}
}

- (void)cancelAction:(id)sender
{
	[locationManager stopUpdatingLocation];
	if ((geoCurrentStatus == GEO_NOTE) && (keyboardShown == YES)) {
		[textView resignFirstResponder];
		textView.text = nil;
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iGeoJournal" message:@"Do you really want to cancel this journal?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
		[alert show];
		[alert release];
		
	}
}

- (void)doneAction:(id)sender
{
	[locationManager stopUpdatingLocation];
	if ((geoCurrentStatus == GEO_NOTE) && (keyboardShown == YES)) {
		[textView resignFirstResponder];
		self.myTitle = getTitle(textView.text);
		self.myNote = textView.text;
	}
	else {
		[self checkLocationUpdateStatus];
		[self cleanView:geoCurrentStatus];
		[self.navigationController dismissModalViewControllerAnimated:YES];
		// TODO: save information to database
		//[self saveToDatabase];
		self.myAudio = self.audioController.recordFilePath;
		self.journalTaken = JOURNAL_TAKEN;
	}
}

- (void)saveToDatabase
{
	/* TODO: how about title???
	 *  1. get the default category.
	 *  2. get all of the strings 
	 *  3. get an entity from the database
	 *  4. save to database.
	 */
	NSManagedObjectContext *managedObjectContext = [[GeoDatabase sharedGeoDatabaseInstance] managedObjectContext];
	Journal *journal = (Journal *)[NSEntityDescription insertNewObjectForEntityForName:@"Journal" inManagedObjectContext:managedObjectContext];
	
	if (myNote || myLocation || myPicture || myAudio) {
		if (myAudio) [journal setAudio:myAudio];
		if (myLocation) [journal setAddress:myLocation];
		if (myPicture) [journal setPicture:myPicture];
		if (myNote) [journal setText:myNote];
		
		if (location != nil) {
			[journal setLongitude:[NSNumber numberWithDouble:location.coordinate.longitude]];
			[journal setLatitude:[NSNumber numberWithDouble:location.coordinate.latitude]];	
			TRACE("%s, lo: %f, la: %f\n", __func__, location.coordinate.longitude, location.coordinate.latitude);
		}
		
		NSError *error;
		if (![managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"%s, $@", __func__, error);
		}
	}
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

/* The preferred way to relinquish ownership of any object (including those in outlets) is to use 
   the corresponding accessor method to set the value of the object to nil. 
   However, if you do not have an accessor method for a given object, you may have to release the object explicitly.
 */
- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	// In some case, however, I want to keep that. 
	TRACE("%s\n", __func__);
	[super viewDidUnload];

	self.titleMapAccuracy = nil;
	self.mapButton = nil;
	self.pictureButton = nil;
	self.noteButton = nil;
	self.voiceButton = nil;
	//self.toolBar = nil;
	self.insideView = nil;
	self.textView = nil;
	self.mapView = nil;
	self.backgroundImage = nil;
	self.precisionForMap = nil;
	//self.myAudio = nil;
	//self.myPicture = nil;
	//self.myNote = nil;
	//self.myLocation = nil;
	//self.audioController = nil;
	//self.locateImage = nil;
	//self.onImage = nil;
	//self.notLoadedImage = nil;
	//self.location = nil;
			
	self.navigationItem.leftBarButtonItem = nil;
	self.navigationItem.rightBarButtonItem = nil;
	self.myAudio = self.audioController.recordFilePath;
}


- (void)dealloc {
	TRACE("%s\n", __func__);
	[titleMapAccuracy release];
	[precisionForMap release];
	[locationManager stopUpdatingLocation];
	[myTitle release];
	[backgroundImage release];
	[titleForJournal release];
	[textBackground release];
	[mapButton release];
	[pictureButton release];
	[noteButton release];
	[voiceButton release];
	[toolBar release];
	[insideView release];
	[textView release];
	[pictureView release];

	[myAudio release];
	[myPicture release];
	[myNote release];
	[myLocation release];
	[mapView release];
	
	[locateImage release]; 
	[onImage release];
		
	[geoCoder release];
	[location release];
	[locationManager release];
	[audioController release];
	[cameraController release];
	[pictureTakenImage release];
	[thumbnailImage release];
	
	[super dealloc];
}


@end
