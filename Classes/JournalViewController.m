//
//  JournalViewController.m
//  GeoJournal
//
//  Created by Jae Han on 7/10/09.
//  Copyright 2009 Home. All rights reserved.
//
//#define CLOUD_TEST 1
//#define DB_TEST 1
#import "JournalViewController.h"
#import "GCategory.h"
#import "GeoDatabase.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "TableCellView.h"
#import "GeoDefaults.h"
#import "JournalEntryViewController.h"
#import "GeoTakeController.h"
#import "ButtonScrollView.h"
#import "DefaultCategory.h"
#import "NoteViewController.h"
#import "GeoJournalAppDelegate.h"
#import "HorizontalViewController.h"
#import "DateIndex.h"
#import "CloudService.h"

#ifdef BANNDER_AD
#import "QWAd.h"
#import "QWAdView.h"

#define PUBLISHER_ID						@"e6d105cec6324d80b6f76c7a86a0a188"
#define SITE_ID								@"PROSPECT-g2rm2l4o"
#endif

#define UUID_LOC                            2
#define	BUTTON_WIDTH						100
#define BUTTON_MARGIN						3
#define BUTTON_HEIGHT						20
#define BUTTON_Y							7
#define BUTTON_SCROLL_HEIGHT				32.0
#define kCustomButtonHeight					30.0
#define LEFT_MIN_POSITION					20.0
#define RIGHT_MAX_POSITION					310.0
#define RIGHT_ARROW_MARGIN                  17.0
#define BUTTON_FRAME_MARGIN                 32.0


extern NSString *getPrinterableDate(NSDate *date, NSInteger *day);
extern NSString *getThumbnailFilename(NSString *filename); 
extern NSString *getThumbnailOldFilename(NSString *filename); 
extern void saveImageToFile(UIImage *image, NSString *filename);
extern UIImage *getReducedImage(UIImage *image, float ratio);

void GET_COORD_IN_PROPORTION(CGSize size, UIImage *image, float *atX, float *atY) {
	
	if (image.size.width > image.size.height) { // Landscape  
		*atX = size.width; 
		*atY = image.size.height * (size.width / image.size.width); 
		TRACE("%s, original: w: %f, h: %f, landscape y: %f\n", __func__, image.size.width, image.size.height, *atY);
	}	
	else { // Portrait 
		*atX = image.size.width * (size.height / image.size.height); 
		*atY = size.height; 
		TRACE("%s, original: w: %f, h: %f, portrait x: %f\n", __func__, image.size.width, image.size.height, *atX);
	} 
}


@implementation JournalViewController

#ifdef BANNDER_AD
@synthesize bannerAd = _bannerAd;
#endif
@synthesize leftArrow;
@synthesize rightArrow;

@synthesize categoryLabel;
@synthesize backgroundLabel;
@synthesize backgroundLabel2;
@synthesize uploadSelectedIcon;
@synthesize uploadNotSelectedIcon;
@synthesize picasaIcon;
@synthesize editCategoryController;
@synthesize categoryEditView;
@synthesize infoButtonImage;
@synthesize selectionImage;
@synthesize tableView;
@synthesize defaultImage;
@synthesize journalArray;
@synthesize _dateArray;
@synthesize isCategoryChanged;
@synthesize _journalView;
@synthesize journalController;
@synthesize buttons;
@synthesize defaultCategory;
@synthesize buttonFrame;
@synthesize categoryArray;
@synthesize selectedCategory;
@synthesize selectedColor;
@synthesize listImage;
@synthesize buttonView;
@synthesize backgroundView;
//@synthesize metadataSearch;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		self.defaultImage = [UIImage imageNamed:@"journal-image-background.png"];
		NSMutableArray *array = [[NSMutableArray alloc] init];
		self._dateArray = array;
		[array release];
		needToReload = NO;
		picasaSyncing = NO;
		/*
		CFBundleRef mainBundle;
		mainBundle = CFBundleGetMainBundle ();
		
		// Get the URL to the sound file to play
		soundFileURLRef  =	CFBundleCopyResourceURL (
													 mainBundle,
													 CFSTR ("click"),
													 CFSTR ("aif"),
													 NULL
													 );
		
		// Create a system sound object representing the sound file
		AudioServicesCreateSystemSoundID (
										  soundFileURLRef,
										  &soundFileObject
										  );		
		 */
    }
    return self;
}

/*
 * enumerateFileAndSync
 *   will enumerate all files in the database and save it into cloud. 
 *   1. decide how to sync the files
 *   2. can we say that all are synced at once. 
 */
- (void)enumerateFilesAndSync
{
    int pc = 0;
    NSArray *category = [GeoDatabase sharedGeoDatabaseInstance].categoryArray;
    
    TRACE("%s\n", __func__);
    for (GCategory *c in category) {
        NSArray *journals = [[GeoDatabase sharedGeoDatabaseInstance] journalByCategory:c];
        
        for (Journal *j in journals) {
            TRACE("Journal: %s\n", [j.title UTF8String]);
            if (j.picture != nil) {
                pc++;
                //NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:image];
                TRACE("  Picture: %s\n", [j.picture UTF8String]);
                NSArray *pictures = [[GeoDatabase sharedGeoDatabaseInstance] picturesForJournal:j.picture];
                if ([pictures count] > 0) {
                    for (NSString *s in pictures) {
                        TRACE("  PO: %s\n", [s UTF8String]);
                    }
                }
            }
            if (j.audio != nil) {
                TRACE("  Audio: %s\n", [j.audio UTF8String]);
            }
        }
    }
}

#ifdef DB_TEST
- (void)insertTestDBEntities
{
	//if ([[GeoDefaults sharedGeoDefaultsInstance].testJournalCreated boolValue] == NO) {
	GCategory *chicago = [self getCategory:@"Chicago Travel"];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"JournalTest" ofType:@"plist"];
    NSMutableArray *testJournal = [[NSMutableArray alloc] initWithContentsOfFile:path];
    path = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
    NSData *imageData = [[NSData alloc] initWithContentsOfFile:path];
    path = [[NSBundle mainBundle] pathForResource:@"1_small" ofType:@"png"];
    NSData *thumb = [[NSData alloc] initWithContentsOfFile:path];
    path = [[NSBundle mainBundle] pathForResource:@"1074077865" ofType:@"aif"];
    NSData *audioData = [[NSData alloc] initWithContentsOfFile:path];
    
    NSString *imageFileName = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:@".png"];
    NSString *thumbFileName = getThumbnailFilename(imageFileName);
    NSString *audioFileName = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:@".aif"];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    [manager createFileAtPath:imageFileName contents:imageData attributes:nil];
    [manager createFileAtPath:thumbFileName contents:thumb attributes:nil];
    [manager createFileAtPath:audioFileName contents:audioData attributes:nil];
    
    [imageData release];
    [audioData release];
    [thumb release];
    [thumbFileName release];
    
    for (NSDictionary *d in testJournal) {
        Journal *journal = [GeoDatabase sharedGeoDatabaseInstance].journalEntity; 
        
        [journal setAudio:[audioFileName lastPathComponent]];
        TRACE("Audio: %s\n", [audioFileName UTF8String]);
        
        [journal setPicture:[imageFileName lastPathComponent]];
        TRACE("Picture: %s\n", [imageFileName UTF8String]);
        
        [journal setText:(NSString*)[d objectForKey:@"text"]];
        [journal setTitle:(NSString*)[d objectForKey:@"title"]];
        
        [journal setCreationDate:(NSDate*)[d objectForKey:@"creationDate"]];
        
        [journal setLongitude:(NSNumber*)[d objectForKey:@"longitude"]];
        [journal setLatitude:(NSNumber*)[d objectForKey:@"latitude"]];
        
        [journal setAddress:(NSString*)[d objectForKey:@"address"]];
        
        [chicago addContentsObject:journal];
    }
    [[GeoDatabase sharedGeoDatabaseInstance] save];
    [GeoDefaults sharedGeoDefaultsInstance].testJournalCreated = [NSNumber numberWithBool:YES];
	//}
	
	// Insert Florida Test
	GCategory *florida = [self getCategory:@"Florida Travel"];
	path = [[NSBundle mainBundle] pathForResource:@"Florida_test" ofType:@"plist"];
	testJournal = [[NSMutableArray alloc] initWithContentsOfFile:path];
	path = [[NSBundle mainBundle] pathForResource:@"1074077865" ofType:@"aif"];
	audioData = [[NSData alloc] initWithContentsOfFile:path];
	audioFileName = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:@".aif"];
	
	//manager = [NSFileManager defaultManager];
	[manager createFileAtPath:audioFileName contents:audioData attributes:nil];
	
	[audioData release];
	
	for (NSDictionary *d in testJournal) {
		Journal *journal = [GeoDatabase sharedGeoDatabaseInstance].journalEntity; 
		
		[journal setAudio:[audioFileName lastPathComponent]];
		TRACE("Audio: %s\n", [audioFileName UTF8String]);
		
		// picture
		NSString *fileName = [d objectForKey:@"picture"];
		path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"jpg"];
		NSData *imageData = [[NSData alloc] initWithContentsOfFile:path];
		path = [[NSBundle mainBundle] pathForResource:[fileName stringByAppendingString:@"_small"] ofType:@"jpg"];
		NSData *thumb = [[NSData alloc] initWithContentsOfFile:path];
		
		NSString *imageFileName = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:@".png"];
		NSString *thumbFileName = getThumbnailFilename(imageFileName);
		[manager createFileAtPath:imageFileName contents:imageData attributes:nil];
		[manager createFileAtPath:thumbFileName contents:thumb attributes:nil];
		
		// 
		
		[journal setPicture:[imageFileName lastPathComponent]];
		TRACE("Picture: %s\n", [imageFileName UTF8String]);
		
		[journal setText:(NSString*)[d objectForKey:@"text"]];
		[journal setTitle:(NSString*)[d objectForKey:@"title"]];
		
		[journal setCreationDate:(NSDate*)[d objectForKey:@"creationDate"]];
		
		[journal setLongitude:(NSNumber*)[d objectForKey:@"longitude"]];
		[journal setLatitude:(NSNumber*)[d objectForKey:@"latitude"]];
		
		[journal setAddress:(NSString*)[d objectForKey:@"address"]];
		
		[florida addContentsObject:journal];
	}
	[[GeoDatabase sharedGeoDatabaseInstance] save];
	
}
#endif

- (void)reloadFetchedResults:(NSNotification*)note 
{
    
    [self loadFromDatabase];
#ifdef CLOUD_TEST
    [self enumerateFilesAndSync];
#endif
    [self setNormalButtons];
    [self initCategoryButtons];
    [self showSelectedButton];
#ifdef DB_TEST
    [self insertTestDBEntities];
#endif	
    // Init scroll view
    [self setScrollViewSize];
    
    self.tabBarController.tabBar.selectedItem.title = @"Journal";
    self.navigationItem.title = nil;
    [self.buttonFrame setExclusiveTouch:YES];
    self.buttonFrame.noteDelegate = self;
    
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.title = selectedCategory.name;
    //self.categoryLabel.text = selectedCategory.name;
    
    //self.tabBarController.tabBar.selectedItem.title = @"Journal";
    
    TRACE("%s, %p\n", __func__, self);
    
    //UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(openTakeJournal:)];
    
    //self.navigationItem.rightBarButtonItem = composeButton;
    //[composeButton release];	
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.0 green:0.4667 blue:0.6078 alpha:1.0];
    
    [self fetchJournalForCategory:self.selectedCategory];
    [self.tableView reloadData];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    TRACE_HERE;
	self.selectionImage = [UIImage imageNamed:@"selection-button.png"];
	self.infoButtonImage = [UIImage imageNamed:@"info-button.png"];
	self.listImage = [UIImage imageNamed:@"list.png"];
	self.picasaIcon = [UIImage imageNamed:@"picasa-icon-small.png"];
	self.uploadSelectedIcon = [UIImage imageNamed:@"upload-selected.png"];
	self.uploadNotSelectedIcon = [UIImage imageNamed:@"upload-notselected.png"];
	self.backgroundLabel = [UIImage imageNamed:@"back-for-time.png"];
	self.backgroundLabel2 = [UIImage imageNamed:@"back-for-time2.png"];
	
	buttons = [[NSMutableArray alloc] init];
	self.selectedColor = [UIColor colorWithRed:0.6043 green:0.5373 blue:0.6510 alpha:1.0];
	//self.selectedColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
	
	NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"DefaultCategory" ofType:@"plist"];
	defaultCategory = [[NSArray alloc] initWithContentsOfFile:thePath];
	
	//self.addCategoryController = nil;
    // observe the app delegate telling us when it's finished asynchronously setting up the persistent store
    [self reloadFetchedResults:nil];
}

- (void)generateDateArray
{
	NSInteger current = -1;
	NSInteger day;
	NSString *dateString;
	int i = 0;
	
	[self._dateArray removeAllObjects];
	for (Journal *j in self.journalArray) {
		dateString = getPrinterableDate(j.creationDate, &day);
		if (current != day) {
			DateIndex *index = [[DateIndex alloc] init];
			index.dateString = dateString;
			index.index = i;
			[self._dateArray addObject:(id)index];
			current = day;
			[index release];
		}
		++i;
	}
}

- (void)fetchJournalForCategory:(GCategory*)category 
{
	if (category == nil) {
		NSLog(@"%s, category object is null.", __func__);
		return;
	}
	
	self.journalArray = [[GeoDatabase sharedGeoDatabaseInstance] journalByCategory:category];
	TRACE("%s, %s, %d\n", __func__, [category.name UTF8String], [self.journalArray count]);
	
	[self generateDateArray];
}

- (void)setReload:(BOOL)reload 
{
	needToReload = reload;
}
/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	TRACE("%s, %d\n", __func__, [journalArray count]);
	
}
*/
#pragma mark TAKE Journal
- (void)saveJournalToDatabase
{
	// NOTE: An absolute path of a document path can be changed betwen restarting app. 
	//       It should get the new path whenever app restart, os it's better keeping 
	//       only the path component.
	//NSManagedObjectContext *managedObjectContext = [[GeoDatabase sharedGeoDatabaseInstance] managedObjectContext];
	Journal *journal = [GeoDatabase sharedGeoDatabaseInstance].journalEntity; 
	
	TRACE("------------ %s --------------\n", __func__);
	
	[journalController closeAudioPlayer];
	
	/* TODO: find out why I have to do this to play audio from a file.
	 *       It seems that we have to change to play.
	 */
	UInt32 category = kAudioSessionCategory_MediaPlayback;
	OSStatus result = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
	if (result) printf("ERROR SETTING AUDIO CATEGORY!\n");
	
	if (journalController.myNote || journalController.myLocation || journalController.myPicture || journalController.myAudio) {
		if (journalController.myAudio) {
			[journal setAudio:[journalController.myAudio lastPathComponent]];
			TRACE("Audio: %s\n", [journalController.myAudio UTF8String]);
		}
		if (journalController.myLocation) {
			[journal setAddress:journalController.myLocation];
			TRACE("Location: %s\n", [journalController.myLocation UTF8String]);
		}
		if (journalController.myPicture) {
			[journal setPicture:[journalController.myPicture lastPathComponent]];
			TRACE("Picture: %s\n", [journalController.myPicture UTF8String]);
		}
		if (journalController.myNote) {
			[journal setText:journalController.myNote];
			TRACE("Note: %s\n", [journalController.myNote UTF8String]);
		}
		if (journalController.myTitle) {
			[journal setTitle:journalController.myTitle];
			TRACE("Title: %s\n", [journalController.myTitle UTF8String]);
		}
		[journal setCreationDate:[NSDate date]];
		if (journalController.location != nil) {
			[journal setLongitude:[NSNumber numberWithDouble:journalController.location.coordinate.longitude]];
			[journal setLatitude:[NSNumber numberWithDouble:journalController.location.coordinate.latitude]];	
			TRACE("lo: %f, la: %f\n", journalController.location.coordinate.longitude, journalController.location.coordinate.latitude);
		}
		[self.selectedCategory addContentsObject:journal];
		
		[[GeoDatabase sharedGeoDatabaseInstance] save];
		
		//[categoryArray addObject:category];
	}
	TRACE("----------- %s, End of saving. ------------\n", __func__);
	
	// Should be destroyed later. To prolong the life of the delegate.
	//self.journalController = nil;
	
}

- (void)openTakeJournal:(id)sender
{
	//AudioServicesPlaySystemSound (self.soundFileObject);
	
	GeoTakeController *section = [[GeoTakeController alloc] initWithNibName:@"GeoTake" bundle:nil];
	UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:section];
	
	self.journalController = section;
	[section release];
	//nc.navigationBar.backgroundColor = [UIColor blueColor];
	// Navigation Bar on top
	section.titleForJournal = self.selectedCategory.name;
	nc.navigationBar.tintColor = [UIColor colorWithRed:0.0286 green:0.6062 blue:0.3575 alpha:1.0]; // green
	//nc.navigationBar.tintColor = [UIColor colorWithRed:0.6745 green:0.1020 blue:0.1529 alpha:1.0]; // read
	//nc.navigationBar.tintColor = [UIColor colorWithRed:1.0 green:0.97 blue:0.60 alpha:1.0]; // yellow
	
	[self.navigationController presentModalViewController:nc animated:YES];
	[nc release];		
}
#pragma mark -

- (void)viewDidAppear:(BOOL)animated {
	TRACE_HERE;
    [super viewDidAppear:animated];
	
	if (self.editCategoryController) {
		[self.editCategoryController viewDidAppear:animated];
		return;
	}
	
	if (self.journalController && self.journalController.journalTaken == JOURNAL_TAKEN) {
		// save journal to category.
		if (journalController.myPicture && journalController.pictureView.image) {
			saveImageToFile(journalController.pictureView.image, journalController.myPicture);
			NSString *smallImage = getThumbnailFilename(journalController.myPicture);
			saveImageToFile(journalController.thumbnailImage, smallImage);
			[smallImage release];
		}
		journalController.journalTaken = NO;
		[self saveJournalToDatabase];
		
		[self fetchJournalForCategory:self.selectedCategory];
		[self.tableView reloadData];
	}
	else if (journalController && journalController.journalTaken == JOURNAL_CANCELLED) {
		// Should delay destorying controller due to the delegate need to be live longer.
		//self.journalController = nil;
	}
	
	if ([GeoDefaults sharedGeoDefaultsInstance].levelRestored == NO) {
		[self restoreLevel];
	}
	else {
		[GeoDefaults sharedGeoDefaultsInstance].thirdLevel = -1;
		if (self.isCategoryChanged == YES) {
			self.navigationItem.title = selectedCategory.name;
			//self.categoryLabel.text = selectedCategory.name;			
			[self fetchJournalForCategory:self.selectedCategory];
			
			self.isCategoryChanged = NO;
			[self.tableView reloadData];
		}
		else if (needToReload == YES) {
			[self generateDateArray];
			[self.tableView reloadData];
			needToReload = NO;
		}
			
	}
	
	[self scrollToButton:selectedButton];

}

- (void)restoreLevel
{
	JournalEntryViewController *controller = nil;
	
	@try {
		int index = [GeoDefaults sharedGeoDefaultsInstance].thirdLevel;
		if ((index > -1) && ([journalArray count] > 0)) {
			controller = [[JournalEntryViewController alloc] initWithNibName:@"JournalEntryView" bundle:nil];
			controller.entryForThisView = [journalArray objectAtIndex:index];
			controller.hidesBottomBarWhenPushed = YES;
			[self.navigationController pushViewController:controller animated:NO];
			self._journalView = controller;
		}	
	}
	@catch (NSException * e) {
		NSLog(@"%s, %@", __func__, [e reason]);
	}
	@finally {
		[controller release];
		[GeoDefaults sharedGeoDefaultsInstance].levelRestored = YES;
	}
	
}

- (void)reloadJournalArray
{	
	self.journalArray = [[GeoDatabase sharedGeoDatabaseInstance] journalByCategory:self.selectedCategory];
	TRACE("%s, %d\n", __func__, [self.journalArray count]);
}

#pragma mark SETTING Button
- (void)scrollToButton:(NSInteger)index
{
	CGRect rect = CGRectMake((BUTTON_WIDTH+BUTTON_MARGIN)*index, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT);
	
	[self.buttonFrame scrollRectToVisible:rect animated:YES];
	TRACE("%s, %d, %f\n", __func__, index, rect.origin.x);
}

- (GCategory*)getCategory:(NSString*)name withIndex:(NSInteger)i
{
	GCategory *ret = nil;
	int n = 0;
	
	for (GCategory *c in categoryArray) {
		if (([c.name compare:name] == NSOrderedSame) && (i == n)) {
			ret = c;
			break;
		}
		n++;
	}
	
	return ret;
}

- (GCategory*)getCategory:(NSString*)name
{
	GCategory *ret = nil;
	int n = 0;
	
	for (GCategory *c in categoryArray) {
		if ([c.name compare:name] == NSOrderedSame) {
			ret = c;
			break;
		}
		n++;
	}
	
	return ret;
}

- (NSInteger)numberOfCategory
{
	return [self.categoryArray count];
}

- (void)setScrollViewSize
{
	// TODO: come up with right scroll view size.
	
	buttonFrame.contentSize = CGSizeMake((BUTTON_WIDTH+BUTTON_MARGIN)*self.numberOfCategory, BUTTON_SCROLL_HEIGHT); //CGSizeMake(buttonFrame.frame.size.width * [defaultCateogry count], 20.0);
	buttonFrame.showsHorizontalScrollIndicator = NO;
    buttonFrame.showsVerticalScrollIndicator = NO;
    buttonFrame.scrollsToTop = NO;	
}

- (void)showSelectedCategory:(NSString*)text
{
	NSString *s = [[NSString alloc] initWithFormat:@"Selected category: %@", text];
	[s release];
}


- (void)showSelectedButton
{
	UIButton *button = nil;
	NSString *active = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
	/*
	 if ([active compare:NO_ACTIVE_CATEGORY] == NSOrderedSame) {
	 selectedButton = 0;
	 button = [buttons objectAtIndex:0];
	 self.selectedCategory = [self.categoryArray objectAtIndex:0];
	 }
	 else {
	 */
	int i = 0;
	for (UIButton *b in buttons) {
		if ([b.titleLabel.text compare:active] == NSOrderedSame) {
			TRACE("%s, found active category: %s\n", __func__, [active UTF8String]);
			button = b;
			selectedButton = i;
			self.selectedCategory = [self getCategory:active withIndex:i];
			break;
		}
		++i;
	}
	//}
	
	if (button == nil) {
		NSLog(@"%s, button is null. Setting default category", __func__);
		button = [buttons objectAtIndex:0];
		selectedButton = 0;
		GCategory *c = [self.categoryArray objectAtIndex:0];
		active = c.name;
		[GeoDefaults sharedGeoDefaultsInstance].activeCategory = active;
		self.selectedCategory = [self getCategory:active withIndex:0];
	}
	
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
	[button setBackgroundImage:selectionImage forState:UIControlStateDisabled];
}

- (UIButton*)getScrollableButton:(NSString*)title
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[button setTitle:title forState:UIControlStateDisabled];
	[button setTitleColor:selectedColor forState:UIControlStateDisabled];
	//[button addTarget:self action:@selector(selectCategory) forControlEvents:UIControlEventTouchUpInside]; 
	//[button addTarget:self action:@selector(dragToLeft) forControlEvents:UIControlEventTouchDragInside];
	//[button addTarget:self action:@selector(dragToRight) forControlEvents:UIControlEventTouchDragOutside];
	button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12];
	//button.showsTouchWhenHighlighted = YES;
	button.hidden = NO;
	button.enabled = NO; // It has to be disabled. 
	
	return button;
}

- (void)initCategoryButtons
{
	int c = [defaultCategory count];
	CGRect frame = CGRectMake(0, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT);
	
	UIButton *button;
	
	c = [self.categoryArray count];
	
	for (int i=0; i<c; ++i) {
		GCategory *category = [categoryArray objectAtIndex:i];
		//frame.size.width = GET_BUTTON_WIDTH(category.name);
		button = [self getScrollableButton:category.name];
		button.frame = frame;
		frame.origin.x += (BUTTON_WIDTH+BUTTON_MARGIN);//(frame.size.width+BUTTON_MARGIN);
		
		[buttons addObject:button];
		[buttonFrame addSubview:button];		
	}
}

- (void)setNormalButtons
{
	//UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editCategory)];
	UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithImage:listImage style:UIBarButtonItemStyleBordered target:self action:@selector(editCategory:)];
	//UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCategory)];
	UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(openTakeJournal:)];
	
	self.navigationItem.leftBarButtonItem = editButton;
	self.navigationItem.rightBarButtonItem = composeButton;
	//self.navigationItem.rightBarButtonItem = addButton;
	[editButton release]; //[addButton release];
	//[composeButton release];	
	/*
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
											[NSArray arrayWithObjects:
											 [UIImage imageNamed:@"picasa-icon-small.png"],
											 [UIImage imageNamed:@"compose.png"],
											 nil]];
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.frame = CGRectMake(0, 0, 90, kCustomButtonHeight);
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    
	self.navigationItem.rightBarButtonItem = segmentBarItem;
    [segmentBarItem release];
	
	[segmentedControl release];
	*/
}

- (void)addIntroEntry
{
	//if ([[GeoDefaults sharedGeoDefaultsInstance].testJournalCreated boolValue] == NO) {
	GCategory *chicago = [self getCategory:@"Daily Journal"];
	//NSString *path = [[NSBundle mainBundle] pathForResource:@"JournalTest" ofType:@"plist"];
	//NSMutableArray *testJournal = [[NSMutableArray alloc] initWithContentsOfFile:path];
	NSString *path = [[NSBundle mainBundle] pathForResource:@"intro" ofType:@"png"];
	NSData *imageData = [[NSData alloc] initWithContentsOfFile:path];
	path = [[NSBundle mainBundle] pathForResource:@"intro_small" ofType:@"png"];
	NSData *thumb = [[NSData alloc] initWithContentsOfFile:path];
	//path = [[NSBundle mainBundle] pathForResource:@"1074077865" ofType:@"aif"];
	//NSData *audioData = [[NSData alloc] initWithContentsOfFile:path];
	
	NSString *imageFileName = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:@".png"];
	NSString *thumbFileName = getThumbnailFilename(imageFileName);
	//NSString *audioFileName = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:@".aif"];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	
	[manager createFileAtPath:imageFileName contents:imageData attributes:nil];
	[manager createFileAtPath:thumbFileName contents:thumb attributes:nil];
	//[manager createFileAtPath:audioFileName contents:audioData attributes:nil];
	
	[imageData release];
	//[audioData release];
	[thumb release];
	[thumbFileName release];
	
	//for (NSDictionary *d in testJournal) {
		Journal *journal = [GeoDatabase sharedGeoDatabaseInstance].journalEntity; 
		
		//[journal setAudio:[audioFileName lastPathComponent]];
		//TRACE("Audio: %s\n", [audioFileName UTF8String]);
		
		[journal setPicture:[imageFileName lastPathComponent]];
		TRACE("Picture: %s\n", [imageFileName UTF8String]);
		
	[journal setText:@"Thank you for choosing iGeoJournal. iGeoJournal is your one stop application. We are planning many updates ahead. The first upcoming update is synching with Picasa web album. For more detailed information, please visit http://odinasoftware.com.\n\nUse iGeoJournal for your travel, your daily journal, or your restaurant review, iGeoJournal will be perfect companion for you. Enjoy!"]; 
	[journal setTitle:@"Welcome to iGeoJournal."];
		
		[journal setCreationDate:[NSDate date]];
		
		//[journal setLongitude:(NSNumber*)[d objectForKey:@"longitude"]];
		//[journal setLatitude:(NSNumber*)[d objectForKey:@"latitude"]];
		
		//[journal setAddress:(NSString*)[d objectForKey:@"address"]];
		
		[chicago addContentsObject:journal];
	//}
	[[GeoDatabase sharedGeoDatabaseInstance] save];
	//[GeoDefaults sharedGeoDefaultsInstance].testJournalCreated = [NSNumber numberWithBool:YES];
	//}
	
	
}

- (void)verifyDefaultCategories
{
	DefaultCategory *dc = nil;
	
	// only do that for the first run. And what to do for the already installed user.
	NSInteger initDone = [[GeoDefaults sharedGeoDefaultsInstance].defaultInitDone intValue];
	
	if (initDone == 0) {
		for (NSString *categoryName in defaultCategory) {
			dc = nil;
			for (DefaultCategory *c in self.categoryArray) {
				if ([categoryName compare:c.name] == NSOrderedSame) {
					// found one, don't need to add.
					dc = c;
					break;
				}
			}
			if (dc == nil) {
				// don't have one, need to add it.
				DefaultCategory *category = [GeoDatabase sharedGeoDatabaseInstance].defaultCategoryEntity; 
				
				[category setName:categoryName];
				
				[[GeoDatabase sharedGeoDatabaseInstance] save];
				[self.categoryArray addObject:category];
			}
		}
		
		[self addIntroEntry];
	}
}

- (void)loadFromDatabase
{
	// Load from the category database
	self.categoryArray = [GeoDatabase sharedGeoDatabaseInstance].categoryArray;
	
	[self verifyDefaultCategories];	
}

- (void)deSelectButton:(NSInteger)index
{
	UIButton *button = [buttons objectAtIndex:index];
	
	[button setTitleColor:selectedColor forState:UIControlStateDisabled];
	[button setBackgroundImage:nil forState:UIControlStateDisabled];
}

- (void)selectButton:(NSSet*)touches
{	
	int i = 0;
	float x = 0.0;
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self.buttonFrame];
	
	//AudioServicesPlaySystemSound (soundFileObject);
	
	TRACE("%s, touch: x: %f\n", __func__, touchPoint.x);
	for (UIButton *button in buttons) {
		if (touchPoint.x >= x && touchPoint.x <= x+BUTTON_WIDTH) {
			// user selects this button
			[button setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
			[button setBackgroundImage:selectionImage forState:UIControlStateDisabled];
			selectedButton = i;
			self.selectedCategory = [self getCategory:button.currentTitle withIndex:i];
			[GeoDefaults sharedGeoDefaultsInstance].activeCategory = button.currentTitle;
		}
		else {
			[button setTitleColor:selectedColor forState:UIControlStateDisabled];
			[button setBackgroundImage:nil forState:UIControlStateDisabled];
		}
		++i;
		x += BUTTON_WIDTH;
	}
	
	self.navigationItem.title = selectedCategory.name;
	//self.categoryLabel.text = self.selectedCategory.name;
	[self fetchJournalForCategory:self.selectedCategory];
	[self.tableView reloadData];

}


#pragma mark -
#pragma mark EDIT CATEGORY
- (void)selectButtonWithIndex:(NSInteger)index
{	
	UIButton *button = [buttons objectAtIndex:index];
	self.selectedCategory = [self.categoryArray objectAtIndex:selectedButton];
	
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
	[button setBackgroundImage:selectionImage forState:UIControlStateDisabled];
	self.selectedCategory = [self getCategory:button.currentTitle withIndex:index];
	[GeoDefaults sharedGeoDefaultsInstance].activeCategory = button.currentTitle;
}

- (void)addNewScrollableButton:(NSString*)title
{
	CGRect frame = CGRectMake((BUTTON_WIDTH+BUTTON_MARGIN)*[buttons count], BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT);
	UIButton *button = [self getScrollableButton:title];
	button.frame = frame;
	[buttons addObject:button];
	[buttonFrame addSubview:button];
	buttonFrame.contentSize = CGSizeMake((BUTTON_WIDTH+BUTTON_MARGIN)*self.numberOfCategory, BUTTON_SCROLL_HEIGHT); 
	
}

- (void)removeFromScrollableButtons:(NSInteger)index
{
	int i = 0;
	
	for (i=index; i<[buttons count]; ++i) {
		UIButton *b = [buttons objectAtIndex:i];
		[b removeFromSuperview];
	}
	[buttons removeObjectAtIndex:index];
	CGRect frame = CGRectMake((BUTTON_WIDTH+BUTTON_MARGIN)*index, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT);
	for (i=index; i<[buttons count]; ++i) {
		UIButton *b = [buttons objectAtIndex:i];
		b.frame = frame;
		[buttonFrame addSubview:b];
		frame.origin.x += (BUTTON_WIDTH+BUTTON_MARGIN);
	}
	
	if (index == selectedButton) {
		// Removing the default category, should change the default category to journal category
		selectedButton = 0;
		[self selectButtonWithIndex:selectedButton];
		[self scrollToButton:selectedButton];
		UIButton *button = [buttons objectAtIndex:selectedButton];
		[self showSelectedCategory:button.currentTitle];
		self.selectedCategory = [self.categoryArray objectAtIndex:selectedButton];
		self.navigationItem.title = selectedCategory.name;
		//self.categoryLabel.text = self.selectedCategory.name;
		[self fetchJournalForCategory:self.selectedCategory];
		[self.tableView reloadData];
	}
	
}

- (void)editNoteCategory
{
	[self.editCategoryController editCategory];
}

- (void)setEditNoteButtons
{
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(categorySettingDone:)];
	UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editNoteCategory)];
	
	self.navigationItem.leftBarButtonItem = button;
	self.navigationItem.rightBarButtonItem = editButton;
	[button release]; [editButton release];	
}

- (void)editCategory:(id)sender
{
	[self setEditNoteButtons];
	
	self.navigationItem.title = @"Edit Category";
	
	NoteViewController *controller = [[NoteViewController alloc] initWithNibName:@"NoteView" bundle:nil];
	self.editCategoryController = controller;
	[controller release];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationTransition: UIViewAnimationTransitionFlipFromLeft forView:self.view cache:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];
	
	//self._settingView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	// Animations
	//[self.view exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
	//self.currentSlideImageController = [self getImageControllerWithPage:currentSelectedPage];
	//[self.currentSlideImageController._imageView removeFromSuperview];
	
	//controller.view.backgroundColor = [UIColor blackColor];
	controller._journalController = self;
	[self.view addSubview:controller.view];
	//self.navigationController.navigationBarHidden = NO;
	// Commit Animation Block
	[UIView commitAnimations];
	//[controller release];
	
}

- (void)categorySettingDone:(id)sender
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationTransition: UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];
	//self.navigationController.navigationBarHidden = YES;
	// Animations
	//[self.view exchangeSubviewAtIndex:1 withSubviewAtIndex:0];
	[self.editCategoryController.view removeFromSuperview];
	//[self.currentSlideImageController.view addSubview:self.currentSlideImageController._imageView];
	
	[self setNormalButtons];
	self.navigationController.navigationBarHidden = NO;
	self.navigationItem.title = selectedCategory.name;
	//self.categoryLabel.text = self.selectedCategory.name;
	self.navigationItem.title = nil;
	// Commit Animation Block
	[UIView commitAnimations];
	
	self.editCategoryController = nil;
	if (self.isCategoryChanged == YES) {
		self.navigationItem.title = selectedCategory.name;
		//self.categoryLabel.text = selectedCategory.name;			
		[self fetchJournalForCategory:self.selectedCategory];
		
		self.isCategoryChanged = NO;
		[self.tableView reloadData];
		[self deSelectButton:selectedButton];
		[self showSelectedButton];
	}		
	
	[self scrollToButton:selectedButton];
	
	
	//self.categoryLabel.text = self.selectedCategory.name;
	//[self fetchJournalForCategory:self.selectedCategory];
	//[self.tableView reloadData];
	
}

#pragma mark -
#pragma mark PICASA 
- (void)picasaSync
{
	picasaSyncing = YES;
	self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, 0.0, self.tableView.frame.size.width, self.tableView.frame.size.height);
	[self.tableView reloadData];
	
}

#pragma mark -
#pragma mark SEGMENT CONTROLLER
- (void)segmentAction:(id)sender
{
	// The segmented control was clicked, handle it here 
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	TRACE("Segment clicked: %d\n", segmentedControl.selectedSegmentIndex);
	
	switch (segmentedControl.selectedSegmentIndex) {
		case 0:
			[self picasaSync];			
			break;
		case 1:
			[self openTakeJournal:sender];
			break;
		case 2:
		default:
			NSLog(@"%s, index error: %d", __func__, segmentedControl.selectedSegmentIndex);
	}
	
}
#pragma mark -
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	//[GeoDefaults sharedGeoDefaultsInstance].secondLevel = -1;
}
*/

/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

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

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	TRACE("%s, %d\n", __func__, [self._dateArray count]);
    return [self._dateArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title = nil;

	
	if (section < [self._dateArray count]) {
		DateIndex *current = [self._dateArray objectAtIndex:section];
		title = current.dateString;
	}
	
	
	return title;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int count = 0;
	
	TRACE("%s, %d\n", __func__, [journalArray count]);
	int c = [self._dateArray count];
	if (section >= c) {
		NSLog(@"%s, index error: %d", __func__, section);
		return 0;
	}
	
	DateIndex *current = [self._dateArray objectAtIndex:section];
	if (section == c-1) {
		// last index
		count = [self.journalArray count] - current.index;
	}
	else if (section < c-1) {
		DateIndex *next = [self._dateArray objectAtIndex:section+1];
		count = next.index - current.index; 
	}
	else {
		NSLog(@"%s, index error: %d", __func__, section);
		return 0;
	}
	
    return count;
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
        NSString *displayName = [theResult valueForAttribute:(NSString *)NSMetadataItemDisplayNameKey];
        TRACE("result at %d - %s\n", i, [displayName UTF8String]);
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
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableview cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	NSString *imageLink = nil;
	BOOL reusableCell = NO;
	BOOL dontDoAnything = NO;
	BOOL shouldAddImageCell = NO;
	TableCellView *imageRect = nil;
	UIImage *image = nil;
	UILabel *title = nil, *description=nil;
	static NSString *CellIdentifier = @"JournalCell";
	float rect_x = ICON_RECT_X;
	float rect_width = self.view.frame.size.width - IMG_RECT_WIDTH - 10.0 - rect_x - 20.0;
    
	UITableViewCell *cell = [tableview dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
	else {
		reusableCell = YES;
	}
	
	if (indexPath.section >= [self._dateArray count]) {
		NSLog(@"%s, index error: %d", __func__, indexPath.section);
		return nil;
	}
	DateIndex *current = [self._dateArray objectAtIndex:indexPath.section];
	int actualIndex = current.index + indexPath.row;
	Journal *journal = [journalArray objectAtIndex:actualIndex];
	//TRACE("%s, section: %d, row: %d, actual: %d\n", __func__, indexPath.section, indexPath.row, actualIndex);
	if (journal == nil) {
		NSLog(@"%s, journal is null.", __func__);
		return nil;
	}
	/*
	TRACE("%s, Journal entry:\n", __func__);
	TRACE("%s\n", [journal.title UTF8String]);
	TRACE("%s\n", [journal.text UTF8String]);
	TRACE("%s\n", [journal.audio UTF8String]);
	TRACE("%s, long:%f, lat: %f\n", [journal.address UTF8String], [journal.longitude floatValue], [journal.latitude floatValue]);
	TRACE("%s\n", [journal.picture UTF8String]);
	TRACE("\n");
	 */
	
#ifdef ADD_BACKGROUND
	UIImageView *background = (UIImageView*) [cell.contentView viewWithTag:MREADER_BACKGROUND_TAG];
	if (background == nil) {
		background = [[[UIImageView alloc] initWithFrame:CGRectMake(BACK_RECT_X, BACK_RECT_Y, BACK_RECT_WIDTH, BACK_RECT_HEIGHT)] autorelease];
		background.image = self.defaultImage;
		background.tag = MREADER_BACKGROUND_TAG;
		[cell.contentView addSubview:background];
	}
#endif
		
	imageLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:journal.picture];
    //NSString *cloudLink = [[GeoDefaults sharedGeoDefaultsInstance] getCloudURL:journal.picture];
    
    NSArray *components = [imageLink pathComponents];
    
    TRACE("%s, image: %s\n", __func__, [imageLink UTF8String]);
    //TRACE("clude: %s, %p\n", [cloudLink UTF8String], self);
    
    if ([components count] > UUID_LOC) {
        int uuid_loc = [components count] - UUID_LOC;
        NSString *possible_uuid = [components objectAtIndex:uuid_loc];
        
        if ([possible_uuid compare:[GeoDefaults sharedGeoDefaultsInstance].UUID] == 0) {
            // This is local file and the UUID component should be omitted in the actual location.
            NSMutableArray *newPath = [[NSMutableArray alloc] initWithCapacity:[components count]-2];
            
            
            for (int i=0; i<[components count]; ++i) {
                if (i == uuid_loc) continue;
                NSString *s = [components objectAtIndex:i];
                [newPath addObject:s];
            }
            imageLink = [NSString pathWithComponents:newPath];
            TRACE("%s: new path: %s\n", __func__, [imageLink UTF8String]);
        }
    }
     
    //[self searchInCloud:@"*"];
	if (imageLink != nil) {
		NSString *thumb = getThumbnailFilename(imageLink);
		if ([[NSFileManager defaultManager] fileExistsAtPath:thumb] == YES) {
			imageLink = thumb;
		}
		else {
            // When the thumb is not available, create it here. This is for iCloud sync.
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:imageLink];
            UIImage *small = getReducedImage(image, THUMBNAIL_RATIO);
            TRACE("%s: small ref count: %d\n", __func__, [small retainCount]);
            saveImageToFile(small, thumb);
            [small release];
            [image release];
            
            
			imageLink = thumb;
		}
		[imageLink retain];
		[thumb release];

	}
	
	title = (UILabel*)[cell.contentView viewWithTag:MREADER_TITLE_TAG];
	rect_x += 5.0;
	if (title == nil) {
		title = [[[UILabel alloc] initWithFrame:CGRectMake(rect_x, TITLE_RECT_Y, rect_width, TITLE_RECT_HEIGHT)] autorelease]; 
		title.tag = MREADER_TITLE_TAG;
		title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];//[UIFont systemFontOfSize:14.0]; 
		title.textColor = [UIColor colorWithRed:0.23 green:0.35 blue:0.60 alpha:1.0]; //[UIColor blackColor]; 
		title.lineBreakMode = UILineBreakModeWordWrap; 
		title.numberOfLines = 1;
		//title.autoresizingMask = UIViewAutoresizingFlexibleWidth | 	UIViewAutoresizingFlexibleHeight; 
	}
	else {
		title.frame = CGRectMake(rect_x, TITLE_RECT_Y, rect_width, TITLE_RECT_HEIGHT);
	}
	
	if (imageLink == nil) {
		// no image, bigger width for description
		rect_width += IMG_RECT_WIDTH;
	}
	description = (UILabel*)[cell.contentView viewWithTag:MREADER_DESCRIPTION_TAG];
	if (description == nil) {
		description = [[[UILabel alloc] initWithFrame:CGRectMake(rect_x, DESC_RECT_Y, rect_width, DESC_RECT_HEIGHT)] autorelease];
		description.tag = MREADER_DESCRIPTION_TAG;
		description.font = [UIFont fontWithName:@"HelveticaNeue" size:12];//[UIFont systemFontOfSize:12.0];
		description.textColor = [UIColor grayColor];
		description.lineBreakMode = UILineBreakModeTailTruncation;
		description.numberOfLines = 4;
		//description.autoresizingMask = UIViewAutoresizingFlexibleWidth | 	UIViewAutoresizingFlexibleHeight; 
	}
	else {
		description.frame = CGRectMake(rect_x, DESC_RECT_Y, rect_width, DESC_RECT_HEIGHT);
	}
	
	// TODO: even thought tablecell can be reused, there is no guarantee to be the same imageRect can be reutilized.
	imageRect = (TableCellView*)[cell.contentView viewWithTag:MREADER_IMG_TAG];
	rect_x = rect_width + 15.0;
	if (imageRect == nil) {
		imageRect = [[[TableCellView alloc] initWithFrame:CGRectMake(rect_x, IMG_RECT_Y, IMG_RECT_WIDTH, IMG_RECT_HEIGHT)] autorelease];
		imageRect.image = nil; 
		imageRect.tag = MREADER_IMG_TAG;
		[imageRect setImageLink:NO_IMAGE_AVAIABLE];
	}
	
	if (imageLink == nil) {
		imageRect.image = nil;
	}
	// 
	float x, y, move_x, move_y;
	
	if (imageLink != nil) {		
		// Image link is available.
		//			[storage addImage:image];
		if (imageRect.image == nil) {
			shouldAddImageCell = YES;
		}
		
		if (imageRect.image == nil || [imageRect compareImageLink:imageLink] == NO) {
			// new image link is set
			if (([imageRect compareImageLink:DEFAULT_IMAGE] == NO) && (imageRect.image != nil)) {
				imageRect.image = nil;
			}
			NSData *data = [[NSData alloc] initWithContentsOfFile:imageLink];
			TRACE("%s, %s, %d\n", __func__, [imageLink UTF8String], [data length]);
			//image = [[UIImage alloc] initWithContentsOfFile:imageLink];
			image = [[UIImage alloc] initWithData:data];
			if (image == nil) {
				NSLog(@"%s, %@ is null.", __func__, imageLink);
			}
			else {
				imageRect.image = image;
				
				imageRect.frame = CGRectMake(rect_x, IMG_RECT_Y, IMG_RECT_WIDTH, IMG_RECT_HEIGHT);
				GET_COORD_IN_PROPORTION(imageRect.frame.size, imageRect.image, &x, &y);
				move_x = x - imageRect.frame.size.width;
				move_y = y - imageRect.frame.size.height;
				move_x = MAKE_CENTER(move_x);
				move_y = MAKE_CENTER(move_y);
				// TODO: make them center
				TRACE("%s, image: w: %f, h: %f\n", __func__, image.size.width, image.size.height);
				TRACE("%s, move_x: %f, move_y: %f x: %f, y: %f\n", __func__, move_x, move_y, x, y);
				imageRect.frame = CGRectMake(imageRect.frame.origin.x+move_x, imageRect.frame.origin.y+move_y, x, y);
				
				[imageRect setImageLink:imageLink];
				if ((reusableCell == NO) || (shouldAddImageCell == YES))
					[cell.contentView addSubview:imageRect];
				
				[image release];
				[imageLink release];
			}
			[data release];
		}
		else {
			dontDoAnything = YES;
			// Still we have to adjust x because there is very good change that image rect can be apprered in
			// different cell.
			imageRect.frame = CGRectMake(rect_x, IMG_RECT_Y, IMG_RECT_WIDTH, IMG_RECT_HEIGHT);
			GET_COORD_IN_PROPORTION(imageRect.frame.size, imageRect.image, &x, &y);
			move_x = x - imageRect.frame.size.width;
			move_y = y - imageRect.frame.size.height;
			move_x = MAKE_CENTER(move_x);
			move_y = MAKE_CENTER(move_y);
			
			imageRect.frame = CGRectMake(imageRect.frame.origin.x+move_x, imageRect.frame.origin.y+move_y, x, y);
			
		}
		
	}
	else if (imageRect.image != nil) {
		imageRect.image = nil;
	}
	/*
	else if ([imageRect compareImageLink:DEFAULT_IMAGE] == NO) {
		// The current image in the cell is not default image.
		// Change to default image.
		if (imageRect.image != nil) {
			imageRect.image = nil;
		}
		//imageRect.frame = CGRectMake(IMG_RECT_X, IMG_RECT_Y, IMG_RECT_WIDTH, IMG_RECT_HEIGHT);
		//imageRect.image = self.defaultImage;
		//[imageRect setImageLink:DEFAULT_IMAGE];
		//if (reusableCell == NO)
		//	[cell.contentView addSubview:imageRect];
	}
	 */
	else {
		dontDoAnything = YES;
	}
	
	DEBUG_RECT("Image:", imageRect.frame);
	
	NSString *text = journal.title;
	if ((title.text == nil) || 
		([title.text compare:text] != NSOrderedSame)) {
		title.text = text;
		//NSLog(@"tableView text: %@", title.text);
		if (reusableCell == NO)
			[cell.contentView addSubview:title];
	}
	
	NSString *descriptionText = journal.text;
	if ((description.text == nil) || 
		([description.text compare:descriptionText] != NSOrderedSame)) {
		description.text = descriptionText;
		if (reusableCell == NO)
			[cell.contentView addSubview:description];
	}
	
	/*
	NSInteger day;
	
	UIImageView *labelBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(BACK_LABEL_RECT_X, BACK_LABEL_RECT_Y, BACK_LABEL_RECT_WIDTH, BACK_LABEL_RECT_HEIGHT)];
	TRACE("%s, %d\n", __func__, indexPath.row);
	if (actualIndex % 2 == 0)
		labelBackgroundView.image = self.backgroundLabel;
	else
		labelBackgroundView.image = self.backgroundLabel2;
	UILabel *timeLabel = [[[UILabel alloc] initWithFrame:CGRectMake(TIME_LABEL_X, TIME_LABEL_Y, TIME_LABEL_WIDTH, TIME_LABEL_HEIGHT)] autorelease];
	//description.tag = MREADER_DESCRIPTION_TAG;
	timeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:10];//[UIFont systemFontOfSize:12.0];
	timeLabel.textColor = [UIColor whiteColor];
	timeLabel.backgroundColor = [UIColor clearColor];
	timeLabel.lineBreakMode = UILineBreakModeTailTruncation;
	timeLabel.numberOfLines = 1;
	timeLabel.text = getPrinterableDate(journal.creationDate, &day);
	
	
	[cell.contentView addSubview:labelBackgroundView];
	
	[cell.contentView addSubview:timeLabel];
	 */
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}


- (void)tableView:(UITableView *)tableview didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft 
        || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        HorizontalViewController *controller = [[HorizontalViewController alloc] initWithNibName:@"HorizontalViewController" bundle:nil];

        //self.navigationController.navigationBarHidden = YES;
        controller.hidesBottomBarWhenPushed = YES;
        controller.view.frame = CGRectMake(0.0, 0.0, 480.0, 320.0);
        [self.navigationController pushViewController:controller animated:NO];
        [controller release];
        
    }
    else {
        JournalEntryViewController *controller = [[JournalEntryViewController alloc] initWithNibName:@"JournalEntryView" bundle:nil];
        self._journalView = controller;
        [controller release];
        
        if (indexPath.section >= [self._dateArray count]) {
            NSLog(@"%s, index error: %d", __func__, indexPath.section);
            return;
        }
        DateIndex *current = [self._dateArray objectAtIndex:indexPath.section];
        int actualIndex = current.index + indexPath.row;
        
        self._journalView.showToolbar = YES;
        self._journalView.entryForThisView = [journalArray objectAtIndex:actualIndex];
        self._journalView._parent = self;
        self._journalView.hidesBottomBarWhenPushed = YES;
        self._journalView.indexForThis = actualIndex;
        [GeoDefaults sharedGeoDefaultsInstance].thirdLevel = actualIndex;
        [self.navigationController pushViewController:self._journalView animated:YES];
        
    }
    
    [tableview deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark SCROLL EVENT
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	//TRACE("%s, x: %f, y: %f\n", __func__, scrollView.contentOffset.x, scrollView.contentOffset.y);	
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	//TRACE("%s, %p, x: %f, y: %f\n", __func__, scrollView, scrollView.contentOffset.x, scrollView.contentOffset.y);	
	if (scrollView == self.buttonFrame) {
		if (scrollView.contentOffset.x < LEFT_MIN_POSITION) {
			self.leftArrow.hidden = YES;
		}
		else if (self.leftArrow.hidden == YES) {
			self.leftArrow.hidden = NO;
		}
		
		if (scrollView.contentOffset.x > RIGHT_MAX_POSITION) {
			self.rightArrow.hidden = YES;
		}
		else if (self.rightArrow.hidden == YES) {
			self.rightArrow.hidden = NO;
		}
	}
}
#pragma mark -

#ifdef BANNDER_AD

#pragma mark QUATTRO
//REQUIRED FOR AD SUPPORT (Use your own delegate in place of SLSMoleculeAppDelegate)
- (void)adView:(QWAdView *)adView dismiss:(UIViewController *)controller
{
	GeoJournalAppDelegate *delegate = (GeoJournalAppDelegate*) [[UIApplication sharedApplication] delegate];
	[[delegate tabBarController] dismissModalViewControllerAnimated:YES];
}
//REQUIRED FOR AD SUPPORT (Use your own delegate in place of SLSMoleculeAppDelegate)
- (void)adView:(QWAdView *)adView displayLandingPage:(UIViewController *)controller
{
	GeoJournalAppDelegate *delegate = (GeoJournalAppDelegate*) [[UIApplication sharedApplication] delegate];
	[[delegate tabBarController] presentModalViewController:controller animated:YES];
}
#pragma mark -
#endif
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)adjustOrientation:(CGRect)bounds
{
    self.view.bounds = bounds;
    [self didRotateFromInterfaceOrientation:0];
}

#ifdef ALLOW_ROTATING
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    TRACE_HERE;
    
    if (self.editCategoryController)
        return NO;
    
    return YES;
}

    CGRect bounds = self.view.bounds;
    
    if (self.editCategoryController) {
        DEBUG_RECT("Edit:", self.editCategoryController.view.frame);
        self.editCategoryController.view.frame = bounds;
    }
    else {
        
        CGRect frame = CGRectMake(self.buttonView.frame.origin.x, self.buttonView.frame.origin.y, 
                                  bounds.size.width, self.buttonView.frame.size.height);
        self.buttonView.frame = frame;
        DEBUG_RECT("buttonview:", self.buttonView.frame);
        frame = CGRectMake(frame.origin.x+BUTTON_FRAME_MARGIN/2, frame.origin.y, frame.size.width-BUTTON_FRAME_MARGIN, frame.size.height);
        self.buttonFrame.frame = frame;
        DEBUG_RECT("buttonframe:", self.buttonFrame.frame);
        self.backgroundView.frame = self.buttonView.frame;
        DEBUG_RECT("button:", self.backgroundView.frame);
        //DEBUG_RECT("left:", self.leftArrow.frame);
        CGRect arrowFrame = CGRectMake(self.buttonView.frame.size.width-RIGHT_ARROW_MARGIN, self.rightArrow.frame.origin.y, 
                                       self.rightArrow.frame.size.width, self.rightArrow.frame.size.height);
        self.rightArrow.frame = arrowFrame;
        DEBUG_RECT("right:", self.rightArrow.frame);
        
        [self scrollToButton:selectedButton];
        [self.tableView reloadData];
    }
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    TRACE_HERE;
}
#endif

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	TRACE_HERE;
	self._journalView = nil;
	self.journalController = nil;
	
	[buttons removeAllObjects];
	
	self.categoryEditView = nil;
	self.tableView = nil;
	self.selectedCategory = nil;
	self.journalController = nil;
	self.defaultCategory = nil;
	self.buttonFrame = nil;
	
	self.selectionImage = nil;
	self.infoButtonImage = nil;
	self.buttons = nil;
	self.selectedColor = nil;
	self.listImage = nil;
	self.leftArrow = nil;
	self.rightArrow = nil;
	
	self.picasaIcon = nil;
	self.uploadSelectedIcon = nil;
	self.uploadNotSelectedIcon = nil;
	self.backgroundLabel = nil;
	self.backgroundLabel2 = nil;
	self.categoryLabel = nil;
    self.buttonView = nil;
    self.backgroundView = nil;
}

- (void)dealloc {
	[leftArrow release];
	[rightArrow release];
	[categoryLabel release];
	[backgroundLabel2 release];
	[backgroundLabel release];
	[uploadSelectedIcon release];
	[uploadNotSelectedIcon release];
	[picasaIcon release];
	[editCategoryController release];
	[categoryEditView release];
	[tableView release];
	[journalController release];
	[_dateArray release];
	[defaultImage release];
	[journalArray release];
	[selectedCategory release];
	[_journalView release];
	
	[listImage release];
	[buttons release];
	[categoryArray release];
	[selectedCategory release];
	[journalController release];
	[defaultCategory release];
	[buttonFrame release];

	[selectedColor release];
	[infoButtonImage release];
	[selectionImage release];
    [buttonView release];
    [backgroundView release];
	
	//AudioServicesDisposeSystemSoundID (soundFileObject);
	//CFRelease (soundFileURLRef);
	
    [super dealloc];
}


@end

