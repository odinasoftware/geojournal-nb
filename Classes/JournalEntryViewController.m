//
//  JournalEntryViewController.m
//  GeoJournal
//
//  Created by Jae Han on 7/13/09.
//  Copyright 2009 Home. All rights reserved.
//
#include <pthread.h>

#import "JournalEntryViewController.h"
#import "GeoDefaults.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "GeoDatabase.h"
#import "GeoSession.h"
#import "FacebookConnect.h"
#import "JournalViewController.h"
#import "EditText.h"
#import "ImageArrayScrollController.h"
#import "FullImageViewController.h"
#import "StatusViewController.h"
#import "HorizontalViewController.h"

//#define CHAR_PER_LINE(x)		x+21
#define LINE_HEIGHT				20
#define BOTTOM_MARGIN			80
#define HEIGHT_WITHOUT_IMAGE	50
#define kCustomButtonHeight		30.0

#define IMAGE_X					0
#define IMAGE_Y					0
#define IMAGE_WIDTH				295
#define IMAGE_HEIGHT			228
#define MAX_FILE_SIZE_ALLOWED	1024*1024

#define ZOOM_BUTTON_X_MARGIN	-2.0
#define ZOOM_BUTTON_Y_MARGIN	50.0

#define ZOOM_IMAGE_WIDTH		310
#define ZOOM_IMAGE_HEIGHT		470

#define IMAGE_HREF						@"http://www.facebook.com"
#define IMAGE_ATTACHMENT_FILENAME		@"GeoJournal_picture_attachment.jpg"
#define AUDIO_ATTACHMENT_FILENAME		@"GeoJournal_audio_attachment.aif"

#define HTML_BODY_TEMPLATE				@"<HTML><BODY><p>%@</p><h6><p><a href='%@'>%@</a></p></h6></BODY></HTML>"

extern NSString *getTitle(NSString *content);
extern NSString *getThumbnailFilename(NSString *filename);
extern NSString *getThumbnailOldFilename(NSString *filename);
extern void saveImageToFile(UIImage *image, NSString *filename);
extern UIImage *getReducedImage(UIImage *image, float ratio);
extern void *display_image_in_thread(void *arg);

double CHAR_PER_LINE(int size) {
	return 35*((double)DEFAULT_FONT_SIZE/size);
}

NSString *getImageHrefForFacebook(float latitude, float longitude)
{
	return [[NSString alloc] initWithFormat:@"http://maps.google.com/maps?q=%f,%f", latitude, longitude];
}

BOOL isDateToday(NSDateComponents *today, NSDateComponents* someday) {
	BOOL ret = NO;
	if ([today year] == [someday year] &&
		[today month] == [someday month] &&
		[today day] == [someday day]) {
		ret = YES;
	}
	
	return ret;
}

BOOL isDateYesterday(NSDateComponents *today, NSDateComponents* someday) {
	BOOL ret = NO;
	if ([today year] == [someday year] &&
		[today month] == [someday month] &&
		([today day] -1 == [someday day])) {
		ret = YES;
	}
	
	return ret;
}
/* for detailed information on Unicode date format patterns, see:
 * <http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns> 
 */
NSString *getPrinterableDate(NSDate *date, NSInteger *day)
{
	NSString *stringDate = nil;
	NSDate *now = [[NSDate alloc] init];
	static NSDateFormatter *dateFormatter = nil;
	static NSCalendar *gregorian = nil; 

	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
	}
	
	if (gregorian == nil) {
		gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	}
	
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
	
	//NSDateComponents *weekdayComponents =
    //[gregorian components:NSWeekdayCalendarUnit fromDate:date];
	NSDateComponents  *compsSomeday = [gregorian components:unitFlags fromDate:date];
	NSDateComponents *compsNow = [gregorian components:unitFlags fromDate:now];
	
	TRACE("%s, day: %d hour: %d: min: %d\n", __func__, [compsSomeday day], [compsSomeday hour], [compsSomeday minute]);
	if (day)
		*day = [compsSomeday day];
	
	if (isDateToday(compsNow, compsSomeday) == YES) {	
		// Print today
		//[dateFormatter setDateFormat:@"Today HH:mm:ss zzz"];
		[dateFormatter setDateFormat:@"'Today, 'h:mm aaa"];
	}
	else if (isDateYesterday(compsNow, compsSomeday) == YES) {
		// Print yesterday
		[dateFormatter setDateFormat:@"'Yesterday, 'h:mm aaa"];
	}
	else {
		// Print standard date.
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	}
	
	stringDate = [dateFormatter stringFromDate:date];
	
	[now release];
	
	return stringDate;
}

int getNumberOfLinefeed(NSString *text) {
	int i=0;
	const char *ptr = [text UTF8String];
	int n = 0;
	
	for (i=0; i<[text length]; ++i) {
		if (ptr[i] == '\n')
			++n;
	}
	
	return n;
}

@implementation JournalEntryViewController

@synthesize imageZoomButton;
@synthesize zoomIn;
@synthesize zoomOut;
@synthesize _parent;
@synthesize indexForThis;
@synthesize _player;
@synthesize scrollView;
@synthesize titleForJournal;
@synthesize imageForJournal;
@synthesize audioButton;
@synthesize audioSlider;
@synthesize textForJournal;
@synthesize entryForThisView;
@synthesize currentTime;
@synthesize duration;
@synthesize _updateTimer;
@synthesize containerView;
@synthesize audioLabel;
@synthesize playButton;
@synthesize pauseButton;
@synthesize creationDateLabel;
@synthesize locationLabel;
@synthesize _fbCall;
@synthesize prevButton;
@synthesize nextButton;
@synthesize toolbar;
@synthesize showToolbar;
@synthesize trashButton;
@synthesize editTextController;
@synthesize increaseFontButton;
@synthesize decreaseFontButton;
@synthesize cameraController = _cameraController;
@synthesize addedPicture, thumbPicture;
//@synthesize imageScrollViewController;
@synthesize imageArrayView;
@synthesize stretchButton, stretchImage;
@synthesize imageFrameView;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		self.playButton = [UIImage imageNamed:@"play-button2.png"];
		self.pauseButton = [UIImage imageNamed:@"pause-2.png"];
		self.zoomIn = [UIImage imageNamed:@"zoom-in.png"];
		self.zoomOut = [UIImage imageNamed:@"zoom.png"];
		self.stretchImage = [UIImage imageNamed:@"full-view.png"];
		self.addedPicture = nil;
		self.thumbPicture = nil;
		
		// Initialize audio file
		CFBundleRef mainBundle;
		mainBundle = CFBundleGetMainBundle ();
		_baseIndex = 0;
		_sync_action = NO_DEFAULT_ACTION;
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
	
    [super viewDidLoad];
	
	TRACE_HERE;
 
	_sync_action = NO_DEFAULT_ACTION;
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
											[NSArray arrayWithObjects:
											 [UIImage imageNamed:@"facebook.png"],
											 [UIImage imageNamed:@"mail1.png"],
											 nil]];
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.frame = CGRectMake(0, 0, 90, kCustomButtonHeight);
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	
	//defaultTintColor = [segmentedControl.tintColor retain];	// keep track of this for later
	
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    [segmentedControl release];
    
	self.navigationItem.rightBarButtonItem = segmentBarItem;
    [segmentBarItem release];
	
	_frameRect = self.imageFrameView.frame;
	_imageRect = self.imageForJournal.frame;
	_containerViewRect = self.containerView.frame;
	_creationDateLabelRect = self.creationDateLabel.frame;
	_locationLabelRect = self.locationLabel.frame;
	_textForJournalRect = self.textForJournal.frame;
	_stretchButtonRect = self.stretchButton.frame;
		
	fontSize = [[GeoDefaults sharedGeoDefaultsInstance].defaultFontSize intValue];
	if (fontSize < DEFAULT_FONT_SIZE) {
		fontSize = DEFAULT_FONT_SIZE;
	}

}

- (void)viewDidAppear:(BOOL)animated
{
	TRACE_HERE;
	if (self.editTextController && self.editTextController.textView.text) {
		TRACE("%s, %s\n", __func__, [self.editTextController.textView.text UTF8String]);
		[self.entryForThisView setTitle:getTitle(self.editTextController.textView.text)];
		[self.entryForThisView setText:self.editTextController.textView.text];
		[[GeoDatabase sharedGeoDatabaseInstance] save];
		self.editTextController = nil;
		
		[self._parent.tableView reloadData];
	}
	else if (self.addedPicture) {
		NSString *name = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:GEO_IMAGE_EXT];
		NSString *smallImage = getThumbnailFilename(name);
		saveImageToFile(self.addedPicture, name);
		saveImageToFile(self.thumbPicture, smallImage);
		[smallImage release];
		
		self.addedPicture = nil;
		self.thumbPicture = nil;
		if (self.entryForThisView.picture == nil) {
			self.entryForThisView.picture = [name lastPathComponent];
			[[GeoDatabase sharedGeoDatabaseInstance] save];
		}
		else {
			[[GeoDatabase sharedGeoDatabaseInstance] savePicture:[name lastPathComponent] toJournal:self.entryForThisView];
		}
	}
	[self reloadView];
}
#pragma mark IMAGE EDIT 

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
	[picker dismissModalViewControllerAnimated:TRUE];
	
	// TODO: Possible API -> UIImageWriteToSavedPhotosAlbum
	UIImage *orig = [info objectForKey:UIImagePickerControllerOriginalImage];
	self.addedPicture = getReducedImage(orig, REDUCE_RATIO);
	self.thumbPicture = getReducedImage(orig, THUMBNAIL_RATIO);		
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[picker dismissModalViewControllerAnimated:TRUE];
}


- (void)retake:(id)sender
{
	//[[CameraThread sharedCameraControllerInstance] startCameraView:self withPicker:self.cameraController];
	_cameraController = [[UIImagePickerController alloc] init];
	self.cameraController.delegate = self;
	self.cameraController.sourceType = UIImagePickerControllerSourceTypeCamera;
	
	[self presentModalViewController:self.cameraController animated:YES];
}

- (void)getImageFromPictureLibrary
{
	_cameraController = [[UIImagePickerController alloc] init];
	self.cameraController.delegate = self;
	self.cameraController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	
	[self presentModalViewController:self.cameraController animated:YES];
}

- (void)getImageFromCameraRoll
{
	_cameraController = [[UIImagePickerController alloc] init];
	self.cameraController.delegate = self;
	self.cameraController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	
	[self presentModalViewController:self.cameraController animated:YES];
	
}

- (void)editImage:(id)sender
{
	UIActionSheet *menu = nil;
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		menu = [[UIActionSheet alloc] initWithTitle:@"Edit Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Take Picture" otherButtonTitles:@"Copy From Photo Library", nil];
		_baseIndex = 0;
	}
	else {
		menu = [[UIActionSheet alloc] initWithTitle:@"Edit Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Copy From Photo Library" otherButtonTitles:nil];
		_baseIndex = 1;
	}


	[menu showInView:self.view];
	[menu release];
}

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (_baseIndex + buttonIndex) {
		case 0:
			// Open camera view
			[self retake:nil];
			break;
		case 1:
			// Open image library
			[self getImageFromPictureLibrary];
			break;
		case 2:
			//[self getImageFromCameraRoll];
			break;

		default:
			break;
	}
}
#pragma mark -
#pragma mark ZOOM_IN_OUT

- (void)openFullView:(CGPoint)point
{
	[self showFullImage:nil];
}

- (void)zoomOut:(id)sender
{
	TRACE_HERE;
	
	if (self.imageForJournal.image != nil) {
		NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self.entryForThisView.picture];
		
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		CGContextRef context = UIGraphicsGetCurrentContext();
		[UIView beginAnimations:nil context:context];
		//[UIView setAnimationTransition: UIViewAnimationTransitionCurlDown forView:self.view cache:YES];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:10.0];
		
#if 0
		UIImageView *imageView = [[UIImageView alloc] init]; //]WithImage:self.imageForJournal.image];
		UIImage *image = [[UIImage alloc] initWithContentsOfFile:pictureLink];					  
		imageView.image = image;
		if (imageView.frame.size.width > 320) {
			imageView.frame = CGRectMake(5, 5, imageView.frame.size.height*0.67, imageView.frame.size.width*0.67);
		}
		else {
			imageView.frame = CGRectMake(5, 5, imageView.frame.size.width*0.67, imageView.frame.size.height*0.67);
		}
#endif	
		// Animations
		//[self.view exchangeSubviewAtIndex:1 withSubviewAtIndex:0];
		//[self._settingView removeFromSuperview];
		//[self.currentSlideImageController.view addSubview:self.currentSlideImageController._imageView];
		[self.view addSubview:self.imageForJournal];
		
		// Commit Animation Block
		[UIView commitAnimations];
		//[image release];
		//[imageView release];
	}
	
}

- (void)showImageZoombutton:(CGRect)imageFrame
{
	float x = imageFrame.origin.x+imageFrame.size.width + ZOOM_BUTTON_X_MARGIN;
	float y = imageFrame.origin.y + ZOOM_BUTTON_Y_MARGIN;
	TRACE("%s, x: %f, y: %f\n", __func__, x, y);
	self.imageZoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.imageZoomButton setBackgroundImage:self.zoomOut forState:UIControlStateNormal];
	
	self.imageZoomButton.frame = CGRectMake(x, y, 20, 20);
	[self.imageZoomButton addTarget:self action:@selector(zoomOut:) forControlEvents:UIControlEventTouchDown];
	[self.scrollView addSubview:self.imageZoomButton];
	
}

#pragma mark -

- (void)reloadView
{
	int moveup = 0;
	float x, y, move, move_x, moveNoArray = 0.0;
	BOOL imageShown = YES;
	NSString *countString = nil;
	
	//self.imageForJournal.frame = CGRectMake(IMAGE_X, IMAGE_Y, IMAGE_WIDTH, IMAGE_HEIGHT);
	NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self.entryForThisView.picture];
	NSMutableArray *pictures = [[GeoDatabase sharedGeoDatabaseInstance] picturesForJournal:self.entryForThisView.picture];
	
	TRACE("%s, number of pictures: %d\n", __func__, [pictures count]);
#if 0
	if (pictures && [pictures count] > 0) {
		// Always the fire will the one with the original. 
		NSString *thumb = getThumbnailFilename(self.entryForThisView.picture);
		if ([[NSFileManager defaultManager] fileExistsAtPath:[[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:thumb]] == NO) {
			[thumb release];
			thumb = getThumbnailOldFilename(self.entryForThisView.picture);
		}
		[pictures insertObject:thumb atIndex:0]; [thumb release];
		self.imageArrayView.hidden = NO;
		self.imageScrollViewController.imageArray = pictures;
		self.imageScrollViewController.firstPicturename = self.entryForThisView.picture;
		//[self.imageScrollViewController performSelectorOnMainThread:@selector(startLoadingImages) withObject:nil waitUntilDone:NO];
		//[self.imageScrollViewController startLoadingImages];
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(startLoadingImageArray:) 
																		   withObject:self.imageScrollViewController waitUntilDone:NO];
	}
	else {
		self.imageArrayView.hidden = YES;
		moveNoArray = self.imageArrayView.frame.size.height;
	}
#endif
	countString = [[NSString alloc] initWithFormat:@"%u", [pictures count]+1];
	[pictures release];

	//_imageRect = CGRectMake(_imageRect.origin.x, 
	//						move,
	//						_imageRect.size.width,
	//						_imageRect.size.height);
	
	TRACE("%s, move y to %f\n", __func__, move);
	UIImage *image = nil;
	if (pictureLink) {
		image = [[UIImage alloc] initWithContentsOfFile:pictureLink];
	}
	
	if (image) {
		self.imageFrameView.hidden = NO;
		
		self.imageForJournal.image = image;
				
		GET_COORD_IN_PROPORTION(_imageRect.size, self.imageForJournal.image, &x, &y);
		
		move_x = _imageRect.size.width - x;
		move = y - _imageRect.size.height - moveNoArray;
		TRACE("%s, x: %f, y: %f, move: %f\n", __func__, x, y, move);
		
		TRACE("%s, y: %f\n", __func__, y);
		//self.imageFrameView.frame = CGRectMake(_frameRect.origin.x, _frameRect.origin.y, 
		//									   _frameRect.size.width, _frameRect.size.height+move);
		self.imageFrameView.frame = CGRectMake(_frameRect.origin.x+move_x/2.0+6, _frameRect.origin.y-moveNoArray-5, x+10, y+10);
		
		self.imageForJournal.frame = CGRectMake(5, 5, x, y);
		
		/*
		UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		activityView.frame = CENTER_RECT(activityView.frame, self.imageFrameView.frame);
		[self.imageForJournal addSubview:activityView];
		[activityView startAnimating];
		[activityView release];
		 */
		
		pthread_t thread;
		image_holder *holder = (image_holder*) malloc(sizeof(image_holder));
		holder->imageView = self.imageForJournal;
		holder->file_name = self.entryForThisView.picture;
		holder->activityView = nil;
		pthread_create(&thread, nil, (void*)(display_image_in_thread), (void*)holder);
		//
		
		//CGRectMake(_imageRect.origin.x+move_x/2.0, _imageRect.origin.y-moveNoArray, x, y);
		DEBUG_RECT("Image for Journal", self.imageForJournal.frame);
		self.stretchButton.hidden = YES;
		self.stretchButton.frame = CGRectMake(_imageRect.origin.x+move_x/2.0+x-5.0, _stretchButtonRect.origin.y - moveNoArray, 
											  _stretchButtonRect.size.width, 
											  _stretchButtonRect.size.height);
		DEBUG_RECT("stretch button:", self.stretchButton.frame);
		
		self.containerView.frame = CGRectMake(_containerViewRect.origin.x, _containerViewRect.origin.y+move, 
											  _containerViewRect.size.width, _containerViewRect.size.height);
		self.creationDateLabel.frame = CGRectMake(_creationDateLabelRect.origin.x, _creationDateLabelRect.origin.y+move, 
												  _creationDateLabelRect.size.width, _creationDateLabelRect.size.height);
		self.locationLabel.frame = CGRectMake(_locationLabelRect.origin.x, _locationLabelRect.origin.y+move, 
											  _locationLabelRect.size.width, _locationLabelRect.size.height);
		self.textForJournal.frame = CGRectMake(_textForJournalRect.origin.x, _textForJournalRect.origin.y+move, 
											   _textForJournalRect.size.width, _textForJournalRect.size.height);
		//self.stretchButton.hidden = NO;
		//[self.view addSubview:self.stretchButton];
		[image release];
		
		self.stretchButton.titleLabel.text = countString; [countString release];
		self.stretchButton.hidden = NO;
	}
	else {
		imageShown = NO;
		self.imageFrameView.hidden = YES;
		self.stretchButton.hidden = YES;
		self.imageForJournal.image = nil;
		moveup = _imageRect.size.height - HEIGHT_WITHOUT_IMAGE - moveNoArray;
		self.imageForJournal.frame = CGRectMake(self.imageForJournal.frame.origin.x, self.imageForJournal.frame.origin.y,
												self.imageForJournal.frame.size.width, HEIGHT_WITHOUT_IMAGE);
		self.containerView.frame = CGRectMake(_containerViewRect.origin.x, _containerViewRect.origin.y-moveup, 
											  _containerViewRect.size.width, self.containerView.frame.size.height);
		self.creationDateLabel.frame = CGRectMake(_creationDateLabelRect.origin.x, _creationDateLabelRect.origin.y-moveup, 
												  _creationDateLabelRect.size.width, _creationDateLabelRect.size.height);
		self.locationLabel.frame = CGRectMake(_locationLabelRect.origin.x, _locationLabelRect.origin.y-moveup, 
											  _locationLabelRect.size.width, _locationLabelRect.size.height);
		self.textForJournal.frame = CGRectMake(_textForJournalRect.origin.x, _textForJournalRect.origin.y-moveup, 
											   _textForJournalRect.size.width, _textForJournalRect.size.height);
	}
	
	if (self.entryForThisView.address) {
		self.locationLabel.text = self.entryForThisView.address;
	}
	self.creationDateLabel.text = getPrinterableDate([self.entryForThisView creationDate], nil); 
	//self.textForJournal.text = @"WASHINGTON - Judge Sonia Sotomayor, President Obama's first nominee to the Supreme Court, introduced herself to the nation Monday by speaking about how her journey from public housing in the Bronx to the federal bench has shaped her philosophy and made her a jurist whose philosophy is guided by fidelity to the law. She said the values she learned as a child guide her as a judge. The task of a judge is not to make the law, it is to apply the law, she said, addressing the assertions of conservative Republicans that she would be guided too much by her personal beliefs. Judge Sotomayor's brief opening statement to the Senate Judiciary Committee ended the first day of a week of hearings in which she is widely expected to be confirmed as the Supreme Court's 111th Justice and its first Hispanic member. 	Judge Sotomayor, who sits on the federal appeals court based in New York City, sat with her right leg encased in a walking cast because she had recently broken her ankle. She spoke after the committee's members demonstrated in their opening statements the sharp partisan divide before which the confirmation hearing will play out, with Democrats and Republicans presenting starkly different views of the candidate and the confirmation process. The progression of my life has been uniquely American, she said, describing how she was raised by a single mother, who emphasized the importance of education for her and her brother, who became a doctor.";
	self.textForJournal.text = self.entryForThisView.text;
	self.titleForJournal.text = self.entryForThisView.title;
	self.titleForJournal.textColor = [UIColor colorWithRed:0.23 green:0.35 blue:0.60 alpha:1.0]; //[UIColor blackColor]; 
	
	self.textForJournal.contentMode = UIViewContentModeTopLeft;
	self.textForJournal.font = [UIFont fontWithName:@"Georgia" size:fontSize];
	CGRect textRect = [self.textForJournal textRectForBounds:_textForJournalRect limitedToNumberOfLines:0];
	self.textForJournal.frame = CGRectMake(self.textForJournal.frame.origin.x, self.textForJournal.frame.origin.y, textRect.size.width, textRect.size.height);
	
	self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, 
											 self.titleForJournal.frame.size.height +
											 self.imageArrayView.frame.size.height +
											 self.imageForJournal.frame.size.height +
											 self.audioButton.frame.size.height +
											 self.audioSlider.frame.size.height +
											 self.textForJournal.frame.size.height + BOTTOM_MARGIN);
		
	// Doesn't work. Don't know why.
	[self.scrollView scrollRectToVisible:CGRectMake(0.0, 0.0, 200.0, 0.1) animated:NO];		
	
	DEBUG_RECT("loc", self.locationLabel.frame);
	DEBUG_RECT("text rect", self.textForJournal.frame);
	[self initializeAudio];
	[self showButtons];
	
	//if (imageShown == YES)
	//	[self showImageZoombutton:self.imageForJournal.frame];
	
}

- (void)showButtons
{
	if (showToolbar == YES) {
		//self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y,
		//								   self.scrollView.frame.size.width, self.scrollView.frame.size.height+self.toolbar.frame.size.height);
		//self.toolbar.frame = CGRectMake(self.toolbar.frame.origin.x, self.toolbar.frame.origin.y+self.toolbar.frame.size.height,
		//								0.0, 0.0);
		//self.toolbar.hidden = NO;
		self.prevButton.enabled = (self.indexForThis == 0?NO:YES);
		self.nextButton.enabled = (self.indexForThis == ([self._parent.journalArray count] -1)?NO:YES);
		self.trashButton.enabled = YES;
	}
	else {
		self.trashButton.enabled = NO;
		self.prevButton.enabled = NO;
		self.nextButton.enabled = NO;
		//self.toolbar.hidden = YES;
	}
}
	
-(void)updateCurrentTimeForPlayer:(AVAudioPlayer *)player
{
	self.currentTime.text = [NSString stringWithFormat:@"%d:%02d", (int)player.currentTime / 60, (int)player.currentTime % 60, nil];
	self.audioSlider.value = player.currentTime;
}

- (void)updateCurrentTime
{
	[self updateCurrentTimeForPlayer:self._player];
}

- (void)updateViewForPlayerState:(AVAudioPlayer *)player
{
	[self updateCurrentTimeForPlayer:player];
	
	if (_updateTimer) 
		[_updateTimer invalidate];
	
	if (player.playing)
	{
		//[_playButton setImage:((player.playing == YES) ? _pauseBtnBG : _playBtnBG) forState:UIControlStateNormal];
		//[_lvlMeter_in setPlayer:player];
		_updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTime) userInfo:player repeats:YES];
	}
	else
	{
		//[_playButton setImage:((player.playing == YES) ? _pauseBtnBG : _playBtnBG) forState:UIControlStateNormal];
		//[_lvlMeter_in setPlayer:nil];
		_updateTimer = nil;
	}
	
}

-(void)updateViewForPlayerInfo:(AVAudioPlayer*)player
{
	self.duration.text = [NSString stringWithFormat:@"%d:%02d", (int)player.duration / 60, (int)player.duration % 60, nil];
	self.audioSlider.maximumValue = player.duration;
	//self._volumeSlider.value = player.volume;
}

- (void)initializeAudio
{
	NSError *error = nil;
	
	NSString *audioLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self.entryForThisView.audio];
	
	if (audioLink) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:audioLink] == YES) {
			NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:audioLink];
			self._player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
			if (error) {
				NSLog(@"%s, %@", __func__, error);
				[fileURL release];
				return;
			}
			
			self.audioButton.exclusiveTouch = YES;
			[self updateViewForPlayerInfo:self._player];
			[self updateViewForPlayerState:self._player];
			[fileURL release];
			return;
		}
	}

	self.audioSlider.enabled = NO;
	self.audioButton.enabled = NO;
	self.audioSlider.value = 0.0;
	self.currentTime.text = [NSString stringWithFormat:@"0.00"];
	self.duration.text = [NSString stringWithFormat:@"0.00"];
	self.audioLabel.text = GEO_AUDIO_NOT_AVAILABLE;
}

#pragma mark SEGMENT CONTROLLER
- (IBAction)segmentAction:(id)sender
{
	// The segmented control was clicked, handle it here 
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	TRACE("Segment clicked: %d\n", segmentedControl.selectedSegmentIndex);
	
	switch (segmentedControl.selectedSegmentIndex) {
		case 0:
			[self syncWithFacebook];
			break;
		case 1:
			[self syncWithMail];
			break;
		case 2:
		default:
			NSLog(@"%s, index error: %d", __func__, segmentedControl.selectedSegmentIndex);
	}
	
}
#pragma mark -
#pragma mark MAIL CONTROLLER delegate
- (void)sendMailWithImage:(NSString*)image
{
	if ([MFMailComposeViewController canSendMail] == NO) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mail is not configured" message:@"Please check your Mail setting." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	else {
		
		MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
		mailController.mailComposeDelegate = self;
		
		NSString *recipient = [GeoDatabase sharedGeoDatabaseInstance].defaultRecipient;
		if (recipient)
			[mailController setToRecipients:[NSArray arrayWithObjects:recipient, nil]];
		
		if (self.entryForThisView.title)
			[mailController setSubject:self.entryForThisView.title];
		
		if (self.entryForThisView.text && self.entryForThisView.address) {
			// when text and address is available.
			NSString *body = [[NSString alloc] initWithFormat:@"<HTML><BODY><p>%@</p><h6><p><a href='%@'>%@</a></p></h6></BODY></HTML>", 
							  self.entryForThisView.text,
							  getImageHrefForFacebook([[self.entryForThisView latitude] floatValue], [[self.entryForThisView longitude] floatValue]),
							  self.entryForThisView.address];
			[mailController setMessageBody:body isHTML:YES];
			[body release];
		}
		else if (self.entryForThisView.text) {
			// When only text is available.
			[mailController setMessageBody:self.entryForThisView.text isHTML:NO];
		}
		if (image) {
			NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:image];
			if (pictureLink) {
				NSData *data = [[NSData alloc] initWithContentsOfFile:pictureLink];
				[mailController addAttachmentData:data mimeType:@"image/jpeg" fileName:IMAGE_ATTACHMENT_FILENAME];
				TRACE("%s, attachment: %s, size: %d\n", __func__, [pictureLink UTF8String], [data length]);
				[data release];
			}
		}
		
		NSString *audioLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self.entryForThisView.audio];
		
		NSDictionary *fileAttrib = [[NSFileManager defaultManager] fileAttributesAtPath:audioLink traverseLink:YES];
		NSNumber *fileSize = nil;
		
		if (fileAttrib == nil) {
			NSLog(@"%s, audio file does not exists.", __func__);
		}
		else {
			if (fileSize = [fileAttrib objectForKey:NSFileSize]) {
				TRACE("File size: %qi\n", [fileSize unsignedLongLongValue]);
				if ([fileSize unsignedLongLongValue] > MAX_FILE_SIZE_ALLOWED) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mail Warning" message:@"Audio file size is bigger than 1M Byte. Audio file will not be attached." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
					[alert show];
					[alert release];
				}
				else {
					NSData *data = [[NSData alloc] initWithContentsOfFile:audioLink];
					[mailController addAttachmentData:data mimeType:@"audio/aif" fileName:AUDIO_ATTACHMENT_FILENAME];
					TRACE("%s, attachment: %s, size: %d\n", __func__, [audioLink UTF8String], [data	length]);
					[data release];
				}
				
			}
		}
		
		[self presentModalViewController:mailController animated:YES];
		[mailController release];
	}
	
}

- (void)syncWithMail
{

	int count = 0;
	NSMutableArray *pictures = [[GeoDatabase sharedGeoDatabaseInstance] picturesForJournal:self.entryForThisView.picture];
	
	TRACE("%s, number of pictures: %d\n", __func__, [pictures count]);
	count += [pictures count];
	if (self.entryForThisView.picture) {
		count++;
	}
	
	if (count > 1) {
		_sync_action = MAIL_SYNC_ACTION;
		[[StatusViewControllerHolder sharedStatusViewControllerInstance] showStatusView:self.tabBarController.view 
																			withJournal:self.entryForThisView 
																			 withImages:pictures 
																			withMessage:@"You have more than one picture. Please select one picture to attach to mail."
																			   delegate:self];
	}
	else {
		[self sendMailWithImage:self.entryForThisView.picture];
	}

	
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	switch (result)
	{
		case MFMailComposeResultCancelled:

			break;[[StatusViewControllerHolder sharedStatusViewControllerInstance] showStatusView:self.tabBarController.view];
		case MFMailComposeResultSaved:

			break;
		case MFMailComposeResultSent:

			break;
		case MFMailComposeResultFailed:

			break;
		default:

			break;
	}
	TRACE("%s, result: %d\n", __func__, result);
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark Facebook Publish and Sync 
- (void)selectImage:(NSString *)picuture
{
	TRACE("%s, will publich this picture: %s\n", __func__, [picuture UTF8String]);
	if (_sync_action == FACEBOOK_SYNC_ACTION) {
		UIImage *image = [[UIImage alloc] initWithContentsOfFile:picuture];
		
		[[GeoSession getFBAgent] publishToFacebookForJournal:self.entryForThisView withImage:image];	
		[image release];
	}
	else {
		[self sendMailWithImage:[picuture lastPathComponent]];
	}

}

- (void)syncWithFacebook
{
	int count = 0;
	NSMutableArray *pictures = [[GeoDatabase sharedGeoDatabaseInstance] picturesForJournal:self.entryForThisView.picture];
	
	TRACE("%s, number of pictures: %d\n", __func__, [pictures count]);
	count += [pictures count];
	if (self.entryForThisView.picture) {
		count++;
	}
	
	if (count > 1) {
		_sync_action = FACEBOOK_SYNC_ACTION;
		[[StatusViewControllerHolder sharedStatusViewControllerInstance] showStatusView:self.tabBarController.view 
																			withJournal:self.entryForThisView 
																			 withImages:pictures 
																			withMessage:nil
																			   delegate:self];
	}
	else {
		[[GeoSession getFBAgent] publishToFacebookForJournal:self.entryForThisView withImage:self.imageForJournal.image];	
	}
}

#pragma mark -
#pragma mark ALERTVIEW delegate
- (void)sync
{
	/*
	if ([GeoSession sharedGeoSessionInstance].fbUID == 0 || [GeoSession sharedGeoSessionInstance].fbUserName == nil) {
		FBLoginDialog* dialog = [[[FBLoginDialog alloc] initWithSession:[GeoSession getFBSession]] autorelease];
		[dialog show];
	}
	 */
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sync Journal" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"E-Mail", @"Facebook", nil];
	[alert show];
	[alert release];
}

- (void)removeThisView
{
	TRACE("%s, %d, %p\n", __func__, self.indexForThis, self.entryForThisView);

	
	if (self.indexForThis == [self._parent.journalArray count]-1) {
		// last entry
		
		if (self.indexForThis > 0) {
			
			[[GeoDatabase sharedGeoDatabaseInstance] deleteJournalObject:self.entryForThisView forCategory:self._parent.selectedCategory];
			[[GeoDatabase sharedGeoDatabaseInstance] save];
			[self._parent reloadJournalArray];
			[self._parent setReload:YES];
			
			[self goPrev:nil];
			[self showButtons];
		}
		else {
			[[GeoDatabase sharedGeoDatabaseInstance] deleteJournalObject:self.entryForThisView forCategory:self._parent.selectedCategory];
			[[GeoDatabase sharedGeoDatabaseInstance] save];
			[self._parent reloadJournalArray];
			[self._parent setReload:YES];
			
			// pop the navigation controller
			[self._parent.navigationController popViewControllerAnimated:YES];
		}
	}
	else if (self.indexForThis < [self._parent.journalArray count]-1) {
		
		[[GeoDatabase sharedGeoDatabaseInstance] deleteJournalObject:self.entryForThisView forCategory:self._parent.selectedCategory];
		[[GeoDatabase sharedGeoDatabaseInstance] save];
		[self._parent reloadJournalArray];
		[self._parent setReload:YES];
		self.indexForThis--;		
		[self goNext:nil];
		[self showButtons];
	}
	else {
		NSLog(@"%s, index error: %d", __func__, self.indexForThis);
	}
		
	TRACE("%s, %d, %p\n", __func__, self.indexForThis, self.entryForThisView);
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0:
			break;
		case 1:
			[self removeThisView];
			break;
		case 2:
			
			break;
		default:
			NSLog(@"%s, index error: %d", __func__, buttonIndex);
	}
}


/*
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0:
			break;
		case 1:
			[self syncWithMail];
			break;
		case 2:
			[self syncWithFacebook];
			break;
		default:
			NSLog(@"%s, index error: %d", __func__, buttonIndex);
	}
}
*/

#pragma mark -
#pragma mark AVAudioPlayer delegate methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	if (flag == NO)
		NSLog(@"Playback finished unsuccessfully");
	
	[self setToPlay];
	[player setCurrentTime:0.];
	[self updateViewForPlayerState:player];
}

- (void)playerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
	NSLog(@"ERROR IN DECODE: %@\n", error); 
}

// we will only get these notifications if playback was interrupted
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
	// the object has already been paused,	we just need to update UI
	[self updateViewForPlayerState:player];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
	[self startPlaybackForPlayer:player];
}


#pragma mark ACTION OUTLETS
- (void)showFullImage:(id)sender
{
	FullImageViewController *controller = [[FullImageViewController alloc] initWithNibName:@"FullImageViewController" bundle:nil];
	
	controller.parent = self;
	
	//self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (void)setToPlay
{
	TRACE_HERE;
	[self.audioButton setImage:playButton forState:UIControlStateNormal];
	self.audioLabel.text = @"Play";
}

- (void)setToPause
{
	[self.audioButton setImage:pauseButton forState:UIControlStateNormal];
	self.audioLabel.text = @"Pause";
}

-(void)pausePlaybackForPlayer:(AVAudioPlayer*)player
{
	[player pause];
	[self updateViewForPlayerState:player];
}

-(void)startPlaybackForPlayer:(AVAudioPlayer*)player
{
	if ([player play])
	{
		[self updateViewForPlayerState:player];
		player.delegate = self;
	}
	else
		NSLog(@"Could not play %@\n", player.url);
}

- (IBAction)playButtonPressed:(UIButton*)sender
{
	if (self._player.playing == YES) {
		[self setToPlay];
		[self pausePlaybackForPlayer: self._player];
	}
	else {
		[self setToPause];
		[self startPlaybackForPlayer: self._player];
	}
}

- (IBAction)progressSliderMoved:(UISlider*)sender
{
	self._player.currentTime = sender.value;
	[self updateCurrentTimeForPlayer:self._player];
}
#pragma mark -
#pragma mark TOOLBAR ACTIONS
- (IBAction)goPrev:(id)sender
{
	// TODO: Memory leak after removing the previous view.
	TRACE_HERE;
	
	if (self.indexForThis > 0) {
		self.indexForThis--;
		CGContextRef context = UIGraphicsGetCurrentContext();
		[UIView beginAnimations:nil context:context];
		[UIView setAnimationTransition: UIViewAnimationTransitionCurlDown forView:self.view cache:YES];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:1.0];
		
		
		self.entryForThisView = [self._parent.journalArray objectAtIndex:self.indexForThis];
		
		[self.scrollView removeFromSuperview];
		
		[self reloadView];
		[self.view addSubview:self.scrollView];
		// Commit Animation Block
		[UIView commitAnimations];
		TRACE("%s, %d\n", __func__, self.indexForThis);
	}
	
}

- (IBAction)goNext:(id)sender
{
	TRACE_HERE;
	int c = [self._parent.journalArray count]-1;
	if (self.indexForThis < c) {
		self.indexForThis++;
		
		CGContextRef context = UIGraphicsGetCurrentContext();
		[UIView beginAnimations:nil context:context];
		[UIView setAnimationTransition: UIViewAnimationTransitionCurlUp forView:self.view cache:YES];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:1.0];
		
		
		self.entryForThisView = [self._parent.journalArray objectAtIndex:self.indexForThis];
		[self.scrollView removeFromSuperview];
		
		[self reloadView];
		[self.view addSubview:self.scrollView];
		// Commit Animation Block
		[UIView commitAnimations];
		TRACE("%s, %d\n", __func__, self.indexForThis);
	}
}

- (IBAction)removeEntry:(id)sender
{
	
	TRACE_HERE;
	
	if (self.indexForThis <= [self._parent.journalArray count]-1) {
		UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Remove Journal" message:@"Do you want to remove this journal?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove",nil];
		[view show];
		[view release];
	}
	
}

- (IBAction)editText:(id)sender
{

	EditText *section = [[EditText alloc] initWithNibName:@"EditText" bundle:nil];
	section.text = self.entryForThisView.text;
	UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:section];
	self.editTextController = section;
	[section release];

	//nc.navigationBar.tintColor = [UIColor colorWithRed:0.0286 green:0.6062 blue:0.3575 alpha:1.0]; // green
	//nc.navigationBar.tintColor = [UIColor colorWithRed:0.6745 green:0.1020 blue:0.1529 alpha:1.0]; // read
	//nc.navigationBar.tintColor = [UIColor colorWithRed:1.0 green:0.97 blue:0.60 alpha:1.0]; // yellow
	
	[self.navigationController presentModalViewController:nc animated:YES];
	[nc release];		
	
}

- (IBAction)increaseFont:(id)sender;
{
	if (fontSize < MAX_FONT_SIZE) {
		fontSize++;
		self.textForJournal.contentMode = UIViewContentModeTopLeft;
		self.textForJournal.font = [UIFont fontWithName:@"Georgia" size:fontSize];
		CGRect textRect = [self.textForJournal textRectForBounds:_textForJournalRect limitedToNumberOfLines:0];
		self.textForJournal.frame = CGRectMake(self.textForJournal.frame.origin.x, self.textForJournal.frame.origin.y, textRect.size.width, textRect.size.height);
		
		//self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x-20, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
		self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.titleForJournal.frame.size.height +
												 self.imageForJournal.frame.size.height +
												 self.audioButton.frame.size.height +
												 self.audioSlider.frame.size.height +
												 self.textForJournal.frame.size.height + BOTTOM_MARGIN);
		
		NSNumber *number = [[NSNumber alloc] initWithInt:fontSize];
		[GeoDefaults sharedGeoDefaultsInstance].defaultFontSize = number;
		[number release];
		[[GeoDefaults sharedGeoDefaultsInstance] saveFontSize];
	}
	
	if (fontSize == MAX_FONT_SIZE) {
		self.increaseFontButton.enabled = NO;
	}
	else if (self.decreaseFontButton.enabled == NO && fontSize > DEFAULT_FONT_SIZE) {
		self.decreaseFontButton.enabled = YES;
	}
}

- (IBAction)decreaseFont:(id)sender
{
	if (fontSize > DEFAULT_FONT_SIZE) {
		fontSize--;
		self.textForJournal.contentMode = UIViewContentModeTopLeft;
		self.textForJournal.font = [UIFont fontWithName:@"Georgia" size:fontSize];
		CGRect textRect = [self.textForJournal textRectForBounds:_textForJournalRect limitedToNumberOfLines:0];
		self.textForJournal.frame = self.textForJournal.frame = CGRectMake(self.textForJournal.frame.origin.x, self.textForJournal.frame.origin.y, textRect.size.width, textRect.size.height);
		
		//self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x-20, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
		self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.titleForJournal.frame.size.height +
												 self.imageForJournal.frame.size.height +
												 self.audioButton.frame.size.height +
												 self.audioSlider.frame.size.height +
												 self.textForJournal.frame.size.height + BOTTOM_MARGIN);
		
		NSNumber *number = [[NSNumber alloc] initWithInt:fontSize];
		[GeoDefaults sharedGeoDefaultsInstance].defaultFontSize = number;
		[number release];
		[[GeoDefaults sharedGeoDefaultsInstance] saveFontSize];
		
	}
	
	if (fontSize == DEFAULT_FONT_SIZE) {
		self.decreaseFontButton.enabled = NO;
	}
	else if (self.increaseFontButton.enabled == NO && fontSize < MAX_FONT_SIZE) {
		self.increaseFontButton.enabled = YES;
	}
}
#pragma mark -

#pragma Rotation
#if 0
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    TRACE_HERE;
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	TRACE_HERE;
    
    DEBUG_RECT("hori:", self.view.frame);
    
    if (fromInterfaceOrientation == UIInterfaceOrientationPortrait ||
        fromInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        
        HorizontalViewController *controller = [[HorizontalViewController alloc] initWithNibName:@"HorizontalViewController" bundle:nil];
        
        UINavigationController *nav = self.navigationController;
        nav.navigationBarHidden = YES;
        controller.hidesBottomBarWhenPushed = YES;
        controller.view.frame = CGRectMake(0.0, 0.0, 480.0, 320.0);
        [nav pushViewController:controller animated:NO];
        [controller release];
        
    }
    else {
        
        UINavigationController *nav = self.navigationController;
        nav.navigationBarHidden = NO;
        [nav popViewControllerAnimated:NO];
        
    }
    
}
#endif
#pragma -
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	TRACE_HERE;
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidDisappear:(BOOL)animated
{
	if (self._player.playing == YES) {
		[self._player stop];
	}
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	TRACE_HERE;
	self.zoomIn = nil;
	self.zoomOut = nil;
	self.imageFrameView = nil;
	self.imageZoomButton = nil;
	self.titleForJournal = nil;
	self.imageForJournal = nil;
	self.audioButton = nil;
	self.audioSlider = nil;
	self.textForJournal = nil;
	self.scrollView = nil;
	self.currentTime = nil;
	self.duration = nil;
	self.containerView = nil;
	self.audioLabel = nil;
	self.creationDateLabel = nil;
	self.locationLabel = nil;
	self.prevButton = nil;
	self.nextButton = nil;
	self.trashButton = nil;
	self.toolbar = nil;
	self.increaseFontButton = nil;
	self.decreaseFontButton = nil;
	self.addedPicture = nil;
	self.thumbPicture = nil;
	//self.imageScrollViewController = nil;
	self.imageArrayView = nil;
	self.stretchButton = nil;
	self.stretchImage = nil;
	
}


- (void)dealloc {
	TRACE_HERE;
	[stretchImage release];
	[addedPicture release];
	[thumbPicture release];
	[_cameraController release];
	[imageZoomButton release];
	[zoomIn release];
	[zoomOut release];
	[editTextController release];
	[trashButton release];
	[toolbar release];
	[prevButton release];
	[nextButton release];
	[creationDateLabel release];
	[locationLabel release];
	[audioLabel release];
	[_updateTimer release];
	[currentTime release];
	[duration release];
	[_player release];
	[scrollView release];
	[titleForJournal release];
	[entryForThisView release];
	[imageForJournal release];
	[audioButton release];
	[audioSlider release];
	[textForJournal release];
	[containerView release];
	[_fbCall release];
	[_parent release];
	[increaseFontButton release];
	[decreaseFontButton release];
	
    [super dealloc];
}


@end
