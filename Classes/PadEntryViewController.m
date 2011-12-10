//
//  PadEntryViewController.m
//  GeoJournal
//
//  Created by Jae Han on 11/14/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "GeoPadHeaders.h"
#import "PadEntryViewController.h"
#import "GeoDefaults.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "GeoDatabase.h"
#import "GeoSession.h"
#import "JournalViewController.h"
#import "EditText.h"
#import "ImageArrayScrollController.h"
#import "FullImageViewController.h"
#import "StatusViewController.h"
#import "HorizontalViewController.h"

extern NSString *getTitle(NSString *content);
extern NSString *getThumbnailFilename(NSString *filename);
extern NSString *getThumbnailOldFilename(NSString *filename);
extern void saveImageToFile(UIImage *image, NSString *filename);
extern UIImage *getReducedImage(UIImage *image, float ratio);
extern void *display_image_in_thread(void *arg);
extern NSString *getPrinterableDate(NSDate *date, NSInteger *day);

@implementation PadEntryViewController

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        TRACE_HERE;
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

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    TRACE_HERE;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _sync_action = NO_DEFAULT_ACTION;
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
											[NSArray arrayWithObjects:
											 [UIImage imageNamed:@"facebook.png"],
											 [UIImage imageNamed:@"mail1.png"],
											 nil]];
	
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

-(void)updateCurrentTimeForPlayer:(AVAudioPlayer *)player
{
	self.currentTime.text = [NSString stringWithFormat:@"%d:%02d", (int)player.currentTime / 60, (int)player.currentTime % 60, nil];
	self.audioSlider.value = player.currentTime;
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
		moveup = _imageRect.size.height - PAD_HEIGHT_WITHOUT_IMAGE - moveNoArray;
		self.imageForJournal.frame = CGRectMake(self.imageForJournal.frame.origin.x, self.imageForJournal.frame.origin.y,
												self.imageForJournal.frame.size.width, PAD_HEIGHT_WITHOUT_IMAGE);
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
											 self.textForJournal.frame.size.height + PAD_BOTTOM_MARGIN);
    
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
		//self.prevButton.enabled = (self.indexForThis == 0?NO:YES);
		//self.nextButton.enabled = (self.indexForThis == ([self._parent.journalArray count] -1)?NO:YES);
		self.trashButton.enabled = YES;
	}
	else {
		self.trashButton.enabled = NO;
		//self.prevButton.enabled = NO;
		//self.nextButton.enabled = NO;
		//self.toolbar.hidden = YES;
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

- (void)viewDidUnload
{
    [super viewDidUnload];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
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
