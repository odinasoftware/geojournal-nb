//
//  JournalEntryViewController.m
//  GeoJournal
//
//  Created by Jae Han on 7/13/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "JournalEntryViewController.h"
#import "GeoDefaults.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "GeoDatabase.h"
#import "GeoSession.h"
#import "FacebookConnect.h"
#import "JournalViewController.h"


#define CHAR_PER_LINE			35
#define LINE_HEIGHT				20
#define BOTTOM_MARGIN			50
#define HEIGHT_WITHOUT_IMAGE	50
#define kCustomButtonHeight		30.0

#define IMAGE_X					0
#define IMAGE_Y					0
#define IMAGE_WIDTH				295
#define IMAGE_HEIGHT			228

#define IMAGE_HREF						@"http://www.facebook.com"
#define IMAGE_ATTACHMENT_FILENAME		@"GeoJournal_picture_attachment.jpg"
#define AUDIO_ATTACHMENT_FILENAME		@"GeoJournal_audio_attachment.aif"

#define HTML_BODY_TEMPLATE				@"<HTML><BODY><p>%@</p><h6><p><a href='%@'>%@</a></p></h6></BODY></HTML>"

NSString *getImageHrefForFacebook(float latitude, float longitude)
{
	return [[NSString alloc] initWithFormat:@"http://maps.google.com/maps?q=%f,%f", latitude, longitude];
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
	NSDateComponents *compsSomeday = [gregorian components:unitFlags fromDate:date];
	NSDateComponents *compsNow = [gregorian components:unitFlags fromDate:now];
	
	TRACE("%s, day: %d hour: %d: min: %d\n", __func__, [compsSomeday day], [compsSomeday hour], [compsSomeday minute]);
	if (day)
		*day = [compsSomeday day];
	if ([compsNow day] == [compsSomeday day]) {
		// Print today
		//[dateFormatter setDateFormat:@"Today HH:mm:ss zzz"];
		[dateFormatter setDateFormat:@"'Today, 'h:mm aaa"];
	}
	else if (([compsNow day] -1) == [compsSomeday day]) {
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

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		self.playButton = [UIImage imageNamed:@"play-button2.png"];
		self.pauseButton = [UIImage imageNamed:@"pause-2.png"];
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
	
}

- (void)viewDidAppear:(BOOL)animated
{
	[self reloadView];
}

- (void)reloadView
{
	int moveup = 0;
	float x, y, move, move_x;
	
	self.imageForJournal.frame = CGRectMake(IMAGE_X, IMAGE_Y, IMAGE_WIDTH, IMAGE_HEIGHT);
	NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self.entryForThisView.picture];
	if (pictureLink) {
		UIImage *image = [[UIImage alloc] initWithContentsOfFile:pictureLink];
		self.imageForJournal.image = image;
		
		GET_COORD_IN_PROPORTION(self.imageForJournal.frame.size, self.imageForJournal.image, &x, &y);
		
		move_x = self.imageForJournal.frame.size.width - x;
		move = y - self.imageForJournal.frame.size.height;
		TRACE("%s, x: %f, y: %f, move: %f\n", __func__, x, y, move);
		
		TRACE("%s, y: %f\n", __func__, y);
		self.imageForJournal.frame = CGRectMake(self.imageForJournal.frame.origin.x+move_x/2.0, self.imageForJournal.frame.origin.y, x, y);
		self.containerView.frame = CGRectMake(self.containerView.frame.origin.x, self.containerView.frame.origin.y+move, 
											  self.containerView.frame.size.width, self.containerView.frame.size.height);
		self.creationDateLabel.frame = CGRectMake(self.creationDateLabel.frame.origin.x, self.creationDateLabel.frame.origin.y+move, 
												  self.creationDateLabel.frame.size.width, self.creationDateLabel.frame.size.height);
		self.locationLabel.frame = CGRectMake(self.locationLabel.frame.origin.x, self.locationLabel.frame.origin.y+move, 
											  self.locationLabel.frame.size.width, self.locationLabel.frame.size.height);
		self.textForJournal.frame = CGRectMake(self.textForJournal.frame.origin.x, self.textForJournal.frame.origin.y+move, 
											   self.textForJournal.frame.size.width, self.textForJournal.frame.size.height);
		[image release];
	}
	else {
		moveup = self.imageForJournal.frame.size.height - HEIGHT_WITHOUT_IMAGE;
		self.imageForJournal.frame = CGRectMake(self.imageForJournal.frame.origin.x, self.imageForJournal.frame.origin.y,
												self.imageForJournal.frame.size.width, HEIGHT_WITHOUT_IMAGE);
		self.containerView.frame = CGRectMake(self.containerView.frame.origin.x, self.containerView.frame.origin.y-moveup, 
											  self.containerView.frame.size.width, self.containerView.frame.size.height);
		self.creationDateLabel.frame = CGRectMake(self.creationDateLabel.frame.origin.x, self.creationDateLabel.frame.origin.y-moveup, 
												  self.creationDateLabel.frame.size.width, self.creationDateLabel.frame.size.height);
		self.locationLabel.frame = CGRectMake(self.locationLabel.frame.origin.x, self.locationLabel.frame.origin.y-moveup, 
											  self.locationLabel.frame.size.width, self.locationLabel.frame.size.height);
		self.textForJournal.frame = CGRectMake(self.textForJournal.frame.origin.x, self.textForJournal.frame.origin.y-moveup, 
											   self.textForJournal.frame.size.width, self.textForJournal.frame.size.height);
	}
	
	if (self.entryForThisView.address) {
		self.locationLabel.text = self.entryForThisView.address;
	}
	self.creationDateLabel.text = getPrinterableDate([self.entryForThisView creationDate], nil); 
	//self.textForJournal.text = @"WASHINGTON - Judge Sonia Sotomayor, President Obama's first nominee to the Supreme Court, introduced herself to the nation Monday by speaking about how her journey from public housing in the Bronx to the federal bench has shaped her philosophy and made her a jurist whose philosophy is guided by fidelity to the law. She said the values she learned as a child guide her as a judge. The task of a judge is not to make the law, it is to apply the law, she said, addressing the assertions of conservative Republicans that she would be guided too much by her personal beliefs. Judge Sotomayor's brief opening statement to the Senate Judiciary Committee ended the first day of a week of hearings in which she is widely expected to be confirmed as the Supreme Court's 111th Justice and its first Hispanic member. 	Judge Sotomayor, who sits on the federal appeals court based in New York City, sat with her right leg encased in a walking cast because she had recently broken her ankle. She spoke after the committee's members demonstrated in their opening statements the sharp partisan divide before which the confirmation hearing will play out, with Democrats and Republicans presenting starkly different views of the candidate and the confirmation process. The progression of my life has been uniquely American, she said, describing how she was raised by a single mother, who emphasized the importance of education for her and her brother, who became a doctor.";
	self.textForJournal.text = self.entryForThisView.text;
	self.titleForJournal.text = self.entryForThisView.title;
	//self.textForJournal.text = @"test";
	int len = [self.textForJournal.text length];
	float line_len = (float) len / CHAR_PER_LINE;
	line_len += getNumberOfLinefeed(self.textForJournal.text);
	len = ceil(line_len);
	if (len <= 0) len = 1;
	self.textForJournal.contentMode = UIViewContentModeTopLeft;
	self.textForJournal.frame = CGRectMake(self.textForJournal.frame.origin.x, self.textForJournal.frame.origin.y, self.textForJournal.frame.size.width, len*LINE_HEIGHT);
	//self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x-20, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
	self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.titleForJournal.frame.size.height +
											 self.imageForJournal.frame.size.height +
											 self.audioButton.frame.size.height +
											 self.audioSlider.frame.size.height +
											 self.textForJournal.frame.size.height + BOTTOM_MARGIN);
	// Doesn't work. Don't know why.
	[self.scrollView scrollRectToVisible:CGRectMake(0.0, -50.0, 200.0, 0.1) animated:NO];		
	
	DEBUG_RECT("loc", self.locationLabel.frame);
	DEBUG_RECT("text rect", self.textForJournal.frame);
	[self initializeAudio];
	[self showButtons];
	
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
				return;
			}
			self.audioButton.exclusiveTouch = YES;
			[self updateViewForPlayerInfo:self._player];
			[self updateViewForPlayerState:self._player];
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
- (void)syncWithMail
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
		
		NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self.entryForThisView.picture];
		if (pictureLink) {
			NSData *data = [[NSData alloc] initWithContentsOfFile:pictureLink];
			[mailController addAttachmentData:data mimeType:@"image/jpeg" fileName:IMAGE_ATTACHMENT_FILENAME];
			TRACE("%s, attachment: %s, size: %d\n", __func__, [pictureLink UTF8String], [data length]);
			[data release];
		}
		
		NSString *audioLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self.entryForThisView.audio];
		if (audioLink) {
			NSData *data = [[NSData alloc] initWithContentsOfFile:audioLink];
			[mailController addAttachmentData:data mimeType:@"audio/aif" fileName:AUDIO_ATTACHMENT_FILENAME];
			TRACE("%s, attachment: %s, size: %d\n", __func__, [audioLink UTF8String], [data	length]);
			[data release];
		}
		
		[self presentModalViewController:mailController animated:YES];
		[mailController release];
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	switch (result)
	{
		case MFMailComposeResultCancelled:

			break;
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

- (void)syncWithFacebook
{
	[[GeoSession getFBAgent] publishToFacebookForJournal:self.entryForThisView withImage:self.imageForJournal.image];
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
			
			[[GeoDatabase sharedGeoDatabaseInstance] deleteJournalObject:self.entryForThisView forCategory:self._parent.categoryForView];
			[[GeoDatabase sharedGeoDatabaseInstance] save];
			[self._parent reloadJournalArray];
			[self._parent setReload:YES];
			
			[self goPrev:nil];
			[self showButtons];
		}
		else {
			[[GeoDatabase sharedGeoDatabaseInstance] deleteJournalObject:self.entryForThisView forCategory:self._parent.categoryForView];
			[[GeoDatabase sharedGeoDatabaseInstance] save];
			[self._parent reloadJournalArray];
			[self._parent setReload:YES];
			
			// pop the navigation controller
			[self._parent.navigationController popViewControllerAnimated:YES];
		}
	}
	else if (self.indexForThis < [self._parent.journalArray count]-1) {
		
		[[GeoDatabase sharedGeoDatabaseInstance] deleteJournalObject:self.entryForThisView forCategory:self._parent.categoryForView];
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

#pragma mark -

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
	
}


- (void)dealloc {
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
	
    [super dealloc];
}


@end