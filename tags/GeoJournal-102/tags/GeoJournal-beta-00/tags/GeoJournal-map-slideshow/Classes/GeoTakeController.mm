//
//  GeoTakeController.m
//  GeoJournal
//
//  Created by Jae Han on 5/27/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <MapKit/MKAnnotationView.h>

#import "GeoTakeController.h"
#import "SpeakHereController.h"
#import "GeoJournalHeaders.h"
#import "GeoMark.h"
#import "CommonObject.h"
#import "GeoDefaults.h"
#import "Journal.h"
#import "GeoDatabase.h"
#import "TextInputController.h"


@implementation GeoTakeController

@synthesize mapButton;
@synthesize pictureButton;
@synthesize noteButton;
@synthesize voiceButton;
@synthesize toolBar;
@synthesize insideView;
@synthesize audioView;
@synthesize textView;
//@synthesize lvlMeter_in;
@synthesize pictureView;
@synthesize mapView;
//@synthesize secondTimer;

@synthesize onImage, offImage, locateImage, notLoadedImage;
@synthesize locationManager, cameraController;
@synthesize myAudio, myPicture, myNote, myLocation;
@synthesize audioController;
@synthesize selectedCategory;
@synthesize location;
@synthesize journalTaken;
@synthesize pictureTakenImage;

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
		self.notLoadedImage = [UIImage imageNamed:@"notloaded.png"];
		
		pictureTakenImage = nil;
		offImage = nil;
		self.locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate=self;
		locationManager.desiredAccuracy=kCLLocationAccuracyHundredMeters; //kCLLocationAccuracyNearestTenMeters;
		
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
    [super viewDidLoad];
	
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
	//self.toolBar.tintColor = [UIColor colorWithRed:0.0 green:0.6368 blue:0.7658 alpha:1.0]; // 
	
	self.navigationItem.title = @"Take Journal";
	
	[self startView:geoCurrentStatus];
	[self registerForKeyboardNotifications];
	self.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	keyboardShown = NO;
	journalTaken = NO;
}

#pragma mark COMMON

- (void) startView:(GeoCurrentStatusType)mode
{
	switch (mode) {
		case GEO_MAP:
			[self toggleButtonMap:nil];
			[self startMapView];
			break;
		case GEO_CAMERA:
			[self toggleButtonPicture:nil];
			[self startCameraView];
			break;
		case GEO_NOTE:
			[self toggleButtonNote:nil];
			[self startNoteView];
			break;
		case GEO_RECORD:
			[self toggleButtonVoice:nil];
			[self startAudioView];
			break;
		default:
			NSLog(@"%s, undefined mode: %d", __func__, mode);
	}
}

- (void) cleanView:(GeoCurrentStatusType)mode 
{
	switch (mode) {
		case GEO_MAP:
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
    CGRect viewFrame = [self.insideView frame];
    viewFrame.size.height -= keyboardSize.height;
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
   
    
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
    CGRect viewFrame = [self.insideView frame];
    viewFrame.size.height += keyboardSize.height;
    self.insideView.frame = viewFrame;
	
    keyboardShown = NO;
}


#pragma mark CameraController

// TODO: view can be unloaded anytime after UIImagePicker controller for camera is activated. 
//       After taking a picture, view is crashing. 

- (void)startCameraView
{
	[self removeSubviews];
	
	UIBarButtonItem	*retake = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(retake:)];
	
	NSArray *items = [NSArray arrayWithObjects:retake, nil];
	[self.toolBar setItems:items];
	[retake release]; 
	
	if (self.pictureTakenImage != nil) {
		if (pictureView.image != nil)
			[pictureView.image release];
		pictureView.image = self.pictureTakenImage;
	}
	else {
		if (pictureView.image != notLoadedImage) 
			pictureView.image = notLoadedImage;
	}
	[self.insideView addSubview:pictureView];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
	// TODO: Possible API -> UIImageWriteToSavedPhotosAlbum
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	self.pictureTakenImage = image;
	pictureView.image = self.pictureTakenImage;
	[self.insideView addSubview:pictureView];
	[picker dismissModalViewControllerAnimated:TRUE];
	self.myPicture = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:GEO_IMAGE_EXT];
	// Move to parent controller because of taking too much of time.
	//saveImageToFile(image, self.myPicture);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[picker dismissModalViewControllerAnimated:TRUE];
}

- (void)retake:(id)sender
{
	[self presentModalViewController:cameraController animated:YES];
}

#pragma mark AudioController

- (void)startAudioView
{
	[self removeSubviews];
	
	NSArray *items = [NSArray arrayWithObjects:nil];
	[self.toolBar setItems:items];
	
	// TODO: how to supply file name to the view.
	
	[self.insideView addSubview:audioView];
}

- (void)cleanRecordView
{
	//[self.secondTimer invalidate];
	//self.secondTimer = nil;
	[audioController stopTimer];
}

	
#pragma mark MapController
/*
 * MapView and location manager:
 *   locationManager: can activate by startUpdatingLocation.
 *   MKCoordinateRegion: set zoom level when a coordinate is available.
 *   TODO: how can we set a annotation mark?
 */
- (void)startMapView 
{
	[self removeSubviews];
	
	UIBarButtonItem *locateMe = [[UIBarButtonItem alloc] initWithImage:self.locateImage style:UIBarButtonItemStylePlain target:self action:@selector(locateUser:)];
	NSArray *items = [NSArray arrayWithObjects:locateMe, nil];
	[self.toolBar setItems:items];
	[locateMe release];
	
	
	[self.insideView addSubview:mapView];	
}

- (void)locateUser:(id)sender
{
	/* to use a CLLocationManager object to deliver location events, create an instance, 
	 assign a delegate object to it, configure the desired accuracy and distance filter values, 
	 and call the startUpdatingLocation method. 
	 */
	[locationManager startUpdatingLocation];
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
	
	NSLog(@"%s: %p, %@", __func__, annView, [annotation title]);
	annView.enabled = TRUE;
	annView.canShowCallout = YES;
	annView.animatesDrop = YES;
	[annView setPinColor:MKPinAnnotationColorRed];
	[annView setSelected:YES];
	
	return annView;
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error{
	NSLog(@"Reverse Geocoder Errored, %@", error);
	
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark{
	self.myLocation = [[NSString alloc] initWithFormat:@"%s, %s, %s", [[placemark countryCode] UTF8String],[[placemark administrativeArea] UTF8String], [[placemark locality] UTF8String]];
	TRACE("%s, %s\n", __func__, [self.myLocation UTF8String]);
	//mPlacemark=placemark;
	
	//[mapView addAnnotation:placemark];
}

/* 
 * didUpdateToLocation:
 *   TODO: 1. why is this called twice at least? Why sometimes getting called repeateably. <<-- 
 *         2. It can come from cached data, so it will need to get the timestamp too. 
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
	//mStoreLocationButton.hidden=FALSE;
	self.location=newLocation;
	//One location is obtained.. just zoom to that location
	TRACE("%s, lo: %f, la: %f\n", __func__, newLocation.coordinate.longitude, newLocation.coordinate.latitude);
	TRACE("%s, new: %s, old: %s\n", __func__, [[newLocation description] UTF8String], [[oldLocation description] UTF8String]);
	MKCoordinateRegion region;
	region.center=location.coordinate;
	//Set Zoom level using Span
	MKCoordinateSpan span;
	span.latitudeDelta=.005;
	span.longitudeDelta=.005;
	region.span=span;
	
	GeoMark *park = [[GeoMark alloc] initWithCoordinate:location.coordinate];
	[mapView addAnnotation:park];
	[mapView selectAnnotation:park	animated:YES];
	
	MKReverseGeocoder *coder = [[MKReverseGeocoder alloc] initWithCoordinate:newLocation.coordinate];
	coder.delegate = self;
	[coder start];
	
	[mapView setRegion:region animated:TRUE];
	
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"%s, %@", __func__, error);
}

#pragma mark Generic

- (void)removeSubviews
{
	NSArray *subviews = self.insideView.subviews;
	
	for (UIView *view in subviews) {
		[view removeFromSuperview];
	}
}

- (void)cancelAction:(id)sender
{
	if ((geoCurrentStatus == GEO_NOTE) && (keyboardShown == YES)) {
		[textView resignFirstResponder];
		textView.text = nil;
	}
	else {
		[self cleanView:geoCurrentStatus];
		[self.navigationController dismissModalViewControllerAnimated:YES];
		self.journalTaken = NO;
	}
}

- (void)doneAction:(id)sender
{
	if ((geoCurrentStatus == GEO_NOTE) && (keyboardShown == YES)) {
		[textView resignFirstResponder];
		self.myNote = textView.text;
	}
	else {
		[self cleanView:geoCurrentStatus];
		[self.navigationController dismissModalViewControllerAnimated:YES];
		// TODO: save information to database
		//[self saveToDatabase];
		self.myAudio = self.audioController.recordFilePath;
		self.journalTaken = YES;
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

	//self.mapButton = nil;
	//self.pictureButton = nil;
	//self.noteButton = nil;
	//self.voiceButton = nil;
	//self.toolBar = nil;
	//self.insideView = nil;
	//self.audioView = nil;
	//self.textView = nil;
	//self.pictureView = nil;
	//self.mapView = nil;
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
	//self.toolBar = nil;
}


- (void)dealloc {
	TRACE("%s\n", __func__);
	
	[mapButton release];
	[pictureButton release];
	[noteButton release];
	[voiceButton release];
	[toolBar release];
	[insideView release];
	[audioView release];
	[textView release];

	[myAudio release];
	[myPicture release];
	[myNote release];
	[myLocation release];
	
	[locateImage release]; 
	[onImage release];
	[notLoadedImage release];
		
	[location release];
	[locationManager release];
	[audioController release];
	[cameraController release];
	[pictureTakenImage release];
	
	[super dealloc];
}


@end
