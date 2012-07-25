//
//  GeoPadTableViewController.m
//  GeoJournal
//
//  Created by Jae Han on 10/28/11.
//  Copyright (c) 2011 Home. All rights reserved.
//
#import "GeoJournalHeaders.h"
#import "GeoPadHeaders.h"
#import "GeoPadTableViewController.h"
#import "GCategory.h"
#import "GeoDatabase.h"
#import "Journal.h"
#import "GeoDefaults.h"
#import "DateIndex.h"
#import "DefaultCategory.h"
#import "TableCellView.h"
#import "PadEntryViewController.h"
#import "GeoPopOverController.h"

extern NSString *getPrinterableDate(NSDate *date, NSInteger *day);
extern NSString *getThumbnailFilename(NSString *filename); 
extern NSString *getThumbnailOldFilename(NSString *filename); 
extern void saveImageToFile(UIImage *image, NSString *filename);

CGFloat PAD_DESC_RECT_HEIGHT(UIViewController* s) {
    if (s.interfaceOrientation == UIInterfaceOrientationPortrait || 
        s.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) { 
        return HEIGHTS_FOR_IPAD_TABLE_CELL_IN_PORTRAIT - PAD_DESC_BOTTOM_MARGIN - PAD_TITLE_RECT_HEIGHT;
    }
    else {
        return HEIGHTS_FOR_IPAD_TABLE_CELL_IN_LANDSCAPE - PAD_DESC_BOTTOM_MARGIN - PAD_TITLE_RECT_HEIGHT;
    }
}

@implementation GeoPadTableViewController

//@synthesize toolbar;
@synthesize tableView;
@synthesize journalArray;
@synthesize _dateArray;
//@synthesize titleLabel;
@synthesize defaultCategory;
@synthesize categoryArray;
@synthesize selectedCategory;
@synthesize _journalView;

@synthesize categoryBar, searchBar, settingBar, composeBar, viewsBar, titleLabel;

/*
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
        TRACE_HERE;
		NSMutableArray *array = [[NSMutableArray alloc] init];
		self._dateArray = array;
		[array release];

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

- (GCategory*)getSelectedCategory
{
    GCategory *c = nil;
    
    NSString *active = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
    c = [self getCategory:active];
    
    if (c == nil) {
        c = [self.categoryArray objectAtIndex:0];
    }
	return c;
}

// because the app delegate now loads the NSPersistentStore into the NSPersistentStoreCoordinator asynchronously
// we will see the NSManagedObjectContext set up before any persistent stores are registered
// we will need to fetch again after the persistent store is loaded
- (void)reloadFetchedResults:(NSNotification*)note 
{
    [self loadFromDatabase];
    //self.selectedCategory = [self getCategory:@"Daily Journal"];
    TRACE("%s, selected category: %p\n", __func__, self.selectedCategory);
    self.selectedCategory = [self getSelectedCategory];
    [self fetchJournalForCategory:self.selectedCategory];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    TRACE_HERE;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // TODO: Get the default cateogry from the global class.
    // It will be available after the root view controller, so it should be there when it gets here. 
    // After that, root controller sends (or call) protocol to this class to get the new category. 
    NSString *active = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
    TRACE("%s, active: %s\n", __func__, [active UTF8String]);
    //self.titleLabel.frame = CENTER_RECT(self.titleLabel.frame, self.toolbar.frame);
    //self.titleLabel.text = active;
    self.title = active;
    
    self.titleLabel.text = self.title;
    self.categoryBar.target = self.navigationController;
    self.categoryBar.action = @selector(showCategoryOptions:);
    self.viewsBar.target = self.navigationController;
    self.viewsBar.action = @selector(displayShowOptions:);
                                      
    //[self fetchJournalForCategory:self.selectedCategory];
    NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"DefaultCategory" ofType:@"plist"];
	defaultCategory = [[NSArray alloc] initWithContentsOfFile:thePath];
	
    //[self reloadFetchedResults:nil];
    //self.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | 
    //UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight |
    //UIViewAutoresizingFlexibleBottomMargin;
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    DEBUG_RECT("pad table view in load: ", self.view.frame);
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(reloadFetchedResults:) 
                                                 name:@"RefetchAllDatabaseData" 
                                               object:nil];

    UIView *p = self.view.superview;
    TRACE("%s, view: %p, superview: %p, nav: %p\n", __func__, self.view, self.view.superview, self.navigationController.view);
    DEBUG_RECT("view: ", self.view.frame);
    DEBUG_RECT("parent view: ", p.frame);
    DEBUG_RECT("bounds: ", self.view.bounds);
    DEBUG_POINT("center: ", self.view.center);
    DEBUG_RECT("table: ", self.tableView.frame);
    UIWindow *w = [UIApplication sharedApplication].delegate.window;
    DEBUG_RECT("window: ", w.frame);
    TRACE(">>>>>>>>>>>>>>>>>\n");
    _isRotated = NO;
    _shouldRotate = YES;
    
    PadEntryViewController *controller = nil;
    
    if (self._journalView == nil) {
        controller = [[PadEntryViewController alloc] initWithNibName:@"PadEntryViewController" bundle:nil];
        self._journalView = controller;
        [controller release];
    }

    [self addChildViewController:self._journalView];
    //[[NSNotificationCenter defaultCenter] addObserver: self 
    //                                         selector:@selector(deviceOrientationDidChange:) 
    //                                             name:UIDeviceOrientationDidChangeNotification object: nil];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    TRACE_HERE;
    //Obtaining the current device orientation
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    char *orientation_string;

    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            orientation_string = "UIInterfaceOrientationPortrait";
            break;
        case UIInterfaceOrientationLandscapeLeft:
            orientation_string = "UIInterfaceOrientationLandscapeLeft";
            break;
        case UIInterfaceOrientationLandscapeRight:
            orientation_string = "UIInterfaceOrientationLandscapeRight";
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            orientation_string = "UIInterfaceOrientationPortraitUpsideDown";
            break;
        case UIDeviceOrientationUnknown:
            orientation_string = "Unknown";
            break;
        default:
            break;
    }

    TRACE("%s: orientation: %s\n", __func__, orientation_string);
    
    UIInterfaceOrientation current_orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIDeviceOrientationUnknown || current_orientation == orientation)
        return;
    
    //[[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:YES];
    //Ignoring specific orientations
    
    //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(relayoutLayers) object:nil];
    //Responding only to changes in landscape or portrait
    
    //CGAffineTransform xform = CGAffineTransformMakeRotation(M_PI/2.0);
    //self.view.transform = xform;
    
    
    //CGPoint point = [self.view convertPoint:self.cancelButton.frame.origin toView:self.view];
    //self.cancelButton.frame = CGRectMake(point.x, point.y, self.cancelButton.frame.size.width, self.cancelButton.frame.size.height);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    //self.toolbar = nil;
    self.tableView = nil;
    self.journalArray = nil;
    self._dateArray = nil;
    self._journalView = nil;
    //self.titleLabel = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    DEBUG_RECT("before parent view: ", self.view.superview.frame);
    if (_isRotated == YES)
        self.view.superview.frame = _frame;
    
    TRACE("super: %p, %p\n", self.view.superview, self.navigationController.view);
    TRACE(">>>>>>>>> (%s) <<<<<<<<<<<<< \n", __func__);
    DEBUG_RECT("view: ", self.view.frame);
    DEBUG_RECT("parent view: ", self.view.superview.frame);
    DEBUG_RECT("bounds: ", self.view.bounds);
    DEBUG_RECT("nav view: ", self.navigationController.view.frame);
    TRACE(">>>>>>>>>>>>>>>>>\n");

}

- (void)viewDidAppear:(BOOL)animated
{
    TRACE_HERE;
    [super viewDidAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self._journalView = NULL;
    
    UIView *p = self.view.superview;
    UIView *pp = self.view.superview.superview;
    UIView *ppp = self.view.superview.superview.superview;
    p.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    pp.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    ppp.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    TRACE("%s, superview: %p, super super: %p, %p\n", __func__, p, pp, ppp);
    TRACE("rotation: %x, %x, %x\n", p.autoresizingMask, pp.autoresizingMask, ppp.autoresizingMask);
    self.view.superview.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.navigationController.view.autoresizesSubviews = YES;
    self.view.superview.superview.autoresizesSubviews = YES;
    TRACE(">>>>>>>>> (%s) <<<<<<<<<<<<< \n", __func__);
    DEBUG_RECT("view: ", self.view.frame);
    DEBUG_RECT("parent view: ", p.frame);
    DEBUG_RECT("bounds: ", self.view.bounds);
    DEBUG_RECT("nav view: ", self.navigationController.view.frame);
    TRACE(">>>>>>>>>>>>>>>>>\n");
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    TRACE_HERE;
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    TRACE_HERE;
    [super viewDidDisappear:animated];
}

#pragma ROTATION
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    TRACE_HERE;
	return YES; //_shouldRotate;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    
    self.view.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    DEBUG_RECT("view: ", self.view.frame);
    
    char *orientation;
    CGRect frame;
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            orientation = "UIInterfaceOrientationPortrait";
            frame = CGRectMake(0.0, 00.0, 768.0, 1004.0);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            orientation = "UIInterfaceOrientationLandscapeLeft";
            frame = CGRectMake(00.0, 0.0, 748.0, 1024.0);
            break;
        case UIInterfaceOrientationLandscapeRight:
            orientation = "UIInterfaceOrientationLandscapeRight";
            frame = CGRectMake(0.0, 00.0, 748.0, 1024.0);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            orientation = "UIInterfaceOrientationPortraitUpsideDown";
            frame = CGRectMake(0.0, 00.0, 768.0, 1004.0);
            break;
        default:
            break;
    }
    
    TRACE(">>>>>>>>> (%s, %s) <<<<<<<<<<<\n", __func__, orientation);
    NSLog(@"p: %@, pp: %@, ppp: %@, pppp: %@", self.view.superview.class, 
          self.view.superview.superview.class, 
          self.view.superview.superview.superview.class,
          self.view.superview.superview.superview.superview.class);
    _frame = self.view.frame;
    _isRotated = YES;
    UIView *p = self.view.superview;
    DEBUG_RECT("before parent view: ", p.frame);
    //self.view.superview.frame = frame;
    TRACE("%s, superview: %p\n", __func__, p);
    DEBUG_RECT("view: ", self.view.frame);
    DEBUG_RECT("parent view: ", p.frame);
    DEBUG_RECT("bounds: ", self.view.bounds);
    DEBUG_POINT("center: ", self.view.center);
    //DEBUG_RECT("table: ", self.tableView.frame);
    UIWindow *w = [UIApplication sharedApplication].delegate.window;
    DEBUG_RECT("w: ", w.frame);
    DEBUG_RECT("nav: ", self.navigationController.view.frame);
    TRACE(">>>>>>>>>>>>>>>>>\n");
    if (_journalView) {
        [_journalView willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    
    TRACE_HERE;
    float y_margin = 768.0;
    float x_margin = 1024.0;
    
    char *orientation;
    switch (fromInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            orientation = "UIInterfaceOrientationPortrait";
            break;
        case UIInterfaceOrientationLandscapeLeft:
            orientation = "UIInterfaceOrientationLandscapeLeft";
            break;
        case UIInterfaceOrientationLandscapeRight:
            orientation = "UIInterfaceOrientationLandscapeRight";
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            orientation = "UIInterfaceOrientationPortraitUpsideDown";
            break;
        default:
            break;
    }
    
    UIView *p = self.view.superview;
    
    y_margin = y_margin - p.frame.size.width;
    x_margin = x_margin - p.frame.size.height;
    
    if (y_margin > 0) {
        x_margin = y_margin;
        y_margin = -x_margin;
    }
    else if (x_margin > 0) {
        y_margin = x_margin;
        x_margin = -y_margin;
    }
    
    //self.view.frame = CGRectMake(0.0, 0.0, //x_margin, self.view.frame.origin.y+y_margin, 
    //                             self.view.frame.size.width, self.view.frame.size.height);
    //self.view.superview.frame = CGRectMake(0.0, 0.0, self.view.superview.frame.size.width+x_margin, self.view.superview.frame.size.height+y_margin);
    TRACE(">>>>>>>>> (%s, %s) <<<<<<<<<<<<\n", __func__, orientation);
    TRACE("superview: %p\n", p);
    DEBUG_RECT("view: ", self.view.frame);
    DEBUG_RECT("parent view: ", p.frame);
    DEBUG_RECT("bounds: ", self.view.bounds);
    DEBUG_POINT("center: ", self.view.center);
    //DEBUG_RECT("table: ", self.tableView.frame);
    UIWindow *w = [UIApplication sharedApplication].delegate.window;
    DEBUG_RECT("w: ", w.frame);
    DEBUG_RECT("nav: ", self.navigationController.view.frame);
    TRACE(">>>>>>>>>>>>>>>>>\n");
    [self.tableView reloadData];
    if (_journalView) {
        [_journalView didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
}

#pragma -

- (void)generateDateArray
{
	NSInteger current = -1;
	NSInteger day;
	NSString *dateString;
	int i = 0;
	
    if (self._dateArray == nil) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
		self._dateArray = array;
		[array release];
    }
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
	//[[GeoDatabase sharedGeoDatabaseInstance] save];
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
				
				[self.categoryArray addObject:category];
			}
		}
        // TODO: crash when it tried to access cloud.
		//[[GeoDatabase sharedGeoDatabaseInstance] save];
		[self addIntroEntry];
        
        [[GeoDefaults sharedGeoDefaultsInstance] dbInitDone];
	}
}

- (void)loadFromDatabase
{
	// Load from the category database
	self.categoryArray = [GeoDatabase sharedGeoDatabaseInstance].categoryArray;
	
	[self verifyDefaultCategories];	
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = HEIGHTS_FOR_IPAD_TABLE_CELL_IN_LANDSCAPE;
    
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait ||
        self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        height = HEIGHTS_FOR_IPAD_TABLE_CELL_IN_PORTRAIT;
    }
    return height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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
	float rect_x = PAD_IMG_PAD;
	float rect_width = self.view.frame.size.width - PAD_IMG_RECT_WIDTH - 10.0 - rect_x - 40.0;
    
	UITableViewCell *cell = [tableview dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
	else {
		reusableCell = YES;
	}
	
    TRACE("%s, width: %f, h: %f\n", __func__, cell.frame.size.width, cell.frame.size.height);
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
	if (imageLink != nil) {
		NSString *thumb = getThumbnailFilename(imageLink);
        // TODO: we will have to decide that this can be fetched from cloud. 
        // how do i know it's coming from the cloud. 
		if ([[NSFileManager defaultManager] fileExistsAtPath:thumb] == YES) {
			imageLink = thumb;
		}
		else {
			[thumb release];
			thumb = getThumbnailOldFilename(imageLink);
            if ([[NSFileManager defaultManager] fileExistsAtPath:thumb] == YES) {
                imageLink = thumb;
            }
            /*
            else {
                // Look for this file from the cloud
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"asynchronously added persistent store!");
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"RefetchAllDatabaseData" object:self userInfo:nil];
                    });
                });
            }
             */
		}
		[imageLink retain];
		[thumb release];
	}
	
    // TODO: even thought tablecell can be reused, there is no guarantee to be the same imageRect can be reutilized.
	imageRect = (TableCellView*)[cell.contentView viewWithTag:MREADER_IMG_TAG];
	//rect_x = rect_width + 15.0;
	if (imageRect == nil) {
		imageRect = [[[TableCellView alloc] initWithFrame:CGRectMake(rect_x, PAD_IMG_RECT_Y, 
                                                                     PAD_IMG_RECT_WIDTH, PAD_IMG_RECT_HEIGHT)] autorelease];
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
				
				imageRect.frame = CGRectMake(rect_x, PAD_IMG_RECT_Y, PAD_IMG_RECT_WIDTH, PAD_IMG_RECT_HEIGHT);
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
			imageRect.frame = CGRectMake(rect_x, PAD_IMG_RECT_Y, PAD_IMG_RECT_WIDTH, PAD_IMG_RECT_HEIGHT);
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
	else {
		dontDoAnything = YES;
	}

    UILabel *dateLabel = (UILabel*) [cell.contentView viewWithTag:PAD_DATE_LABEL_TAG];
    if (dateLabel == nil) {
        dateLabel = [[[UILabel alloc] initWithFrame:CGRectMake(rect_x, PAD_DATE_RECT_Y, PAD_DATE_RECT_WIDTH, PAD_DATE_RECT_HEIGHT)] autorelease];
        dateLabel.tag = PAD_DATE_LABEL_TAG;
        dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:10];
        dateLabel.textColor = [UIColor blackColor];
        dateLabel.numberOfLines = 1;
    }
    else {
        dateLabel.frame = CGRectMake(rect_x, PAD_DATE_RECT_Y, PAD_DATE_RECT_WIDTH, PAD_DATE_RECT_HEIGHT);
    }
    dateLabel.text = getPrinterableDate([journal creationDate], nil);
    [cell.contentView addSubview:dateLabel];

    
	title = (UILabel*)[cell.contentView viewWithTag:MREADER_TITLE_TAG];
	rect_x = rect_x + PAD_IMG_RECT_WIDTH + PAD_TEXT_MARGIN;
	if (title == nil) {
		title = [[[UILabel alloc] initWithFrame:CGRectMake(rect_x, PAD_TITLE_RECT_Y, rect_width, PAD_TITLE_RECT_HEIGHT)] autorelease]; 
		title.tag = MREADER_TITLE_TAG;
		title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];//[UIFont systemFontOfSize:14.0]; 
		title.textColor = [UIColor colorWithRed:0.23 green:0.35 blue:0.60 alpha:1.0]; //[UIColor blackColor]; 
		title.lineBreakMode = UILineBreakModeWordWrap; 
		title.numberOfLines = 1;
		//title.autoresizingMask = UIViewAutoresizingFlexibleWidth | 	UIViewAutoresizingFlexibleHeight; 
	}
	else {
		title.frame = CGRectMake(rect_x, PAD_TITLE_RECT_Y, rect_width, PAD_TITLE_RECT_HEIGHT);
	}
	
    DEBUG_RECT("Title:", title.frame);
    
	if (imageLink == nil) {
		// no image, bigger width for description
		rect_width += PAD_IMG_RECT_WIDTH;
	}
	description = (UILabel*)[cell.contentView viewWithTag:MREADER_DESCRIPTION_TAG];
	if (description == nil) {
		description = [[[UILabel alloc] initWithFrame:CGRectMake(rect_x, PAD_DESC_RECT_Y, rect_width, PAD_DESC_RECT_HEIGHT(self))] autorelease];
		description.tag = MREADER_DESCRIPTION_TAG;
		description.font = [UIFont fontWithName:@"HelveticaNeue" size:14];//[UIFont systemFontOfSize:12.0];
		description.textColor = [UIColor grayColor];
		description.lineBreakMode = UILineBreakModeTailTruncation;
		description.numberOfLines = 8;
		//description.autoresizingMask = UIViewAutoresizingFlexibleWidth | 	UIViewAutoresizingFlexibleHeight; 
	}
	else {
		description.frame = CGRectMake(rect_x, PAD_DESC_RECT_Y, rect_width, PAD_DESC_RECT_HEIGHT(self));
	}
	
    DEBUG_RECT("Desc: ", description.frame);
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableview didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    PadEntryViewController *controller = nil;
    
    if (self._journalView == nil) {
        controller = [[PadEntryViewController alloc] initWithNibName:@"PadEntryViewController" bundle:nil];
        self._journalView = controller;
        [controller release];
    }
    
    if (indexPath.section >= [self._dateArray count]) {
        NSLog(@"%s, index error: %d", __func__, indexPath.section);
        return;
    }
    DateIndex *current = [self._dateArray objectAtIndex:indexPath.section];
    int actualIndex = current.index + indexPath.row;
    
    self._journalView.showToolbar = YES;
    self._journalView.entryForThisView = [journalArray objectAtIndex:actualIndex];
    //self._journalView._parent = self;
    //self._journalView.hidesBottomBarWhenPushed = YES;
    self._journalView.indexForThis = actualIndex;
    [GeoDefaults sharedGeoDefaultsInstance].thirdLevel = actualIndex;
    
    _shouldRotate = NO;
    //[self.navigationController pushViewController:self._journalView animated:YES];
    [self.view addSubview:self._journalView.view];
    //[[[UIApplication sharedApplication].delegate navigationController] pushViewController:self._journalView animated:YES];
    //[self presentViewController:self._journalView animated:YES completion:nil];
    //[tableview addSubview:self._journalView.view];

    //controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    TRACE("%s, 0x%x\n", __func__, self.navigationController.view.autoresizingMask);
    [tableview deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Managing the popover

/*
- (void)showRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem {

    // Add the popover button to the toolbar.
    NSMutableArray *itemsArray = [toolbar.items mutableCopy];
    [itemsArray insertObject:barButtonItem atIndex:0];
    [toolbar setItems:itemsArray animated:NO];
    [itemsArray release];
    TRACE("%s, toolbar: %p\n", __func__, toolbar);
}


- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem {
  
    // Remove the popover button from the toolbar.
    NSMutableArray *itemsArray = [toolbar.items mutableCopy];
    [itemsArray removeObject:barButtonItem];
    [toolbar setItems:itemsArray animated:NO];
    [itemsArray release];
    
    TRACE("%s, toolbar: %p\n", __func__, toolbar);
}
 
 */
#pragma mark -
#pragma ChangeCategory

- (void)setCategory:(NSString *)category
{
    self.selectedCategory = [self getCategory:category];
    self.titleLabel.text = category;
    TRACE("%s, selected category: %p\n", __func__, self.selectedCategory);
    [self fetchJournalForCategory:self.selectedCategory];
    [self.tableView reloadData];
    
}
#pragma -


- (void)dealloc {
    //[toolbar release];
    [tableView release];
    [journalArray release];
    [_dateArray release];
    //[titleLabel release];
    [_journalView release];
    
    [super dealloc];
}	




@end
