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
#import "FBConnect/FBFeedDialog.h"


#define CHAR_PER_LINE			35
#define LINE_HIEIGHT			26
#define BOTTOM_MARGIN			50
#define HEIGHT_WITHOUT_IMAGE	50
#define kCustomButtonHeight		30.0

#define IMAGE_X					16
#define IMAGE_Y					60
#define IMAGE_WIDTH				295
#define IMAGE_HEIGHT			172

#define IMAGE_ATTACHMENT_FILENAME		@"GeoJournal_picture_attachment.jpg"
#define AUDIO_ATTACHMENT_FILENAME		@"GeoJournal_audio_attachment.aif"


/* for detailed information on Unicode date format patterns, see:
 * <http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns> 
 */
NSString *getPrinterableDate(NSDate *date)
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

@implementation JournalEntryViewController

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
	int moveup = 0;
	
    [super viewDidLoad];
 
	NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self.entryForThisView.picture];
	if (pictureLink) {
		//self.imageForJournal.frame = CGRectMake(IMAGE_X, IMAGE_Y, IMAGE_WIDTH, IMAGE_HEIGHT);
		self.imageForJournal.image = [[UIImage alloc] initWithContentsOfFile:pictureLink];
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
	self.creationDateLabel.text = getPrinterableDate([self.entryForThisView creationDate]); 
	//self.textForJournal.text = @"WASHINGTON - Judge Sonia Sotomayor, President Obama's first nominee to the Supreme Court, introduced herself to the nation Monday by speaking about how her journey from public housing in the Bronx to the federal bench has shaped her philosophy and made her a jurist whose philosophy is guided by fidelity to the law. She said the values she learned as a child guide her as a judge. The task of a judge is not to make the law, it is to apply the law, she said, addressing the assertions of conservative Republicans that she would be guided too much by her personal beliefs. Judge Sotomayor's brief opening statement to the Senate Judiciary Committee ended the first day of a week of hearings in which she is widely expected to be confirmed as the Supreme Court's 111th Justice and its first Hispanic member. 	Judge Sotomayor, who sits on the federal appeals court based in New York City, sat with her right leg encased in a walking cast because she had recently broken her ankle. She spoke after the committee's members demonstrated in their opening statements the sharp partisan divide before which the confirmation hearing will play out, with Democrats and Republicans presenting starkly different views of the candidate and the confirmation process. The progression of my life has been uniquely American, she said, describing how she was raised by a single mother, who emphasized the importance of education for her and her brother, who became a doctor.";
	self.textForJournal.text = self.entryForThisView.text;
	self.titleForJournal.text = self.entryForThisView.title;
	//self.textForJournal.text = @"test";
	int len = [self.textForJournal.text length];
	float line_len = (float) len / CHAR_PER_LINE;
	len = ceil(line_len);
	if (len <= 0) len = 1;
	self.textForJournal.contentMode = UIViewContentModeTopLeft;
	self.textForJournal.frame = CGRectMake(self.textForJournal.frame.origin.x, self.textForJournal.frame.origin.y, self.textForJournal.frame.size.width, len*LINE_HIEIGHT);
	//self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x-20, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
	self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.titleForJournal.frame.size.height +
							self.imageForJournal.frame.size.height +
							self.audioButton.frame.size.height +
							self.audioSlider.frame.size.height +
							self.textForJournal.frame.size.height + BOTTOM_MARGIN);
	/*
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sync)];
	//FBLoginButton* button = [[[FBLoginButton alloc] init] autorelease];
	self.navigationItem.rightBarButtonItem = button;
	[button release];
	*/
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
	
	[self initializeAudio];
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
		
		if (self.entryForThisView.text)
			[mailController setMessageBody:self.entryForThisView.text isHTML:NO];
		
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
	
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark Facebook Publish and Sync 
/*
 * The templateData property is a string and cannot contain any carriage returns. 
 * It needs to be a JSON-encoded string using the format described in Template Data. 
 * Reserved tokens contain more than one JSON value and can be tricky to add to templateData.
 */
/*
 * Facebook Publish structure 
 */
- (void)publishToFacebook
{
	FBFeedDialog* dialog = [[[FBFeedDialog alloc] init] autorelease];
	dialog.delegate = self;
	dialog.templateBundleId = 102457377053;
	NSString *data = [[NSString alloc] initWithFormat:@"{\"geojournal_body\": \"%@\"}", [self.entryForThisView text]];
	dialog.templateData = data;
	[dialog show];		
	[data release];
	
}

- (void)syncWithFacebook
{
	if ([GeoSession sharedGeoSessionInstance].fbUID == 0 || [GeoSession sharedGeoSessionInstance].fbUserName == nil) {
		FBLoginDialog* dialog = [[[FBLoginDialog alloc] initWithSession:[GeoSession getFBSession:self]] autorelease];
		[dialog show];
	}
	else {
		[self publishToFacebook];
	}
}

- (void)session:(FBSession*)session didLogin:(FBUID)uid {
	NSLog(@"User with id %lld logged in.", uid);
	[GeoSession sharedGeoSessionInstance].fbUID = uid;
	[self getUserName];
}

- (void)getUserName {
	NSString* fql = [[NSString alloc] initWithFormat:@"select name from user where uid == %qu", [GeoSession sharedGeoSessionInstance].fbUID];
	
	NSDictionary* params = [NSDictionary dictionaryWithObject:fql forKey:@"query"];
	self._fbCall = FB_GET_USERNAME;
	[[FBRequest requestWithDelegate:self] call:self._fbCall params:params];
}

- (void)request:(FBRequest*)request didLoad:(id)result {
	TRACE("%s, %s, request succeeded. %d\n", __func__, [self._fbCall UTF8String], result);
	
	if ([self._fbCall compare:FB_GET_USERNAME] == NSOrderedSame) {
		NSArray* users = result;
		NSDictionary* user = [users objectAtIndex:0];
		[GeoSession sharedGeoSessionInstance].fbUserName = [user objectForKey:@"name"];
		// Show user name
		NSLog(@"Query returned %@", [GeoSession sharedGeoSessionInstance].fbUserName);
	}
	
	[self publishToFacebook];
	/*
	// get extended permission.
	FBPermissionDialog* dialog = [[[FBPermissionDialog alloc] init] autorelease];
	dialog.delegate = self;
	dialog.permission = @"status_update";
	[dialog show];
	 */
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error 
{
	NSLog(@"%s, request failed. %@", __func__, error);
}

/* Facebook picture upload.
 http://forum.developers.facebook.com/viewtopic.php?id=30467
 */
- (void)dialogDidSucceed:(FBDialog*)dialog
{
	TRACE_HERE;
	
	NSMutableDictionary *args = [[[NSMutableDictionary alloc] init] autorelease];
	//NSData *imageData = [[NSData alloc] initWithContentsOfFile:[[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self.entryForThisView.picture]];
	//NSData *imageData = [[NSData alloc] initWithContentsOfFile:thePath];
	
	//if (imageData) {
		[args setObject:self.playButton forKey:@"image"];    // 'images' is an array of 'UIImage' objects
		FBRequest *uploadPhotoRequest = [FBRequest requestWithDelegate:self];
		[uploadPhotoRequest call:@"facebook.photos.upload" params:args];
		//[imageData release];
	//}
}

- (void)dialogDidCancel:(FBDialog*)dialog
{
	TRACE_HERE;
}

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError*)error
{
	TRACE_HERE;
	NSLog(@"%s, %@", __func__, error);
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


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
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

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self.imageForJournal = nil;
	self.audioButton = nil;
	self.audioSlider = nil;
	self.textForJournal = nil;
	self.entryForThisView = nil;
	self.titleForJournal = nil;
	self.scrollView = nil;
	self._player = nil;
	self.currentTime = nil;
	self.duration = nil;
	self._updateTimer = nil;
	self.containerView = nil;
	self.audioLabel = nil;
	self.playButton = nil;
	self.pauseButton = nil;
	self.creationDateLabel = nil;
	self.locationLabel = nil;
}


- (void)dealloc {
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
	
    [super dealloc];
}


@end
