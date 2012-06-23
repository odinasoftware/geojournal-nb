//
//  NoteViewController.m
//  GeoJournal
//
//  Created by Jae Han on 5/23/09.
//  Copyright 2009 Home. All rights reserved.
//
#define CLOUD_TEST 1
#import "NoteViewController.h"
#import "GeoTakeController.h"
#import "GeoJournalHeaders.h"
#import "GeoDatabase.h"
#import "AddCategory.h"
#import "GCategory.h"
#import "Journal.h"
#import "GeoDefaults.h"
#import "DefaultCategory.h"
#import "JournalViewController.h"
#import "ButtonScrollView.h"
#import "NoteTableView.h"

#define	BUTTON_WIDTH						100
#define BUTTON_MARGIN						3
#define BUTTON_HEIGHT						20
#define BUTTON_Y							7
#define BUTTON_SCROLL_HEIGHT				32.0

#define GEO_TITLE_RECT_X					10.0
#define GEO_TITLE_RECT_Y					0.0
#define GEO_TITLE_RECT_WIDTH				240	
#define GEO_TITLE_RECT_HEIGHT				40.0

#define GEO_BUTTON_RECT_X					GEO_TITLE_RECT_WIDTH + 10
#define GEO_BUTTON_RECT_Y					12
#define GEO_BUTTON_RECT_WIDTH				40
#define GEO_BUTTON_RECT_HEIGHT				20

#define	JOURNAL_CONTENT_VIEW_TAG			1
#define JOURNAL_INFO_BUTTON_TAG				2
#define THUMBNAIL_EXT						@"_small"

#define GET_BUTTON_WIDTH(x)	([x length] < BUTTON_WIDTH?[x length]+5:BUTTON_WIDTH)

void saveImageToFile(UIImage *image, NSString *filename) 
{
	TRACE("%s, file: %s\n", __func__, [filename UTF8String]);
	/* //I am not sure this will work or not.
	 CGDataProviderRef dataProvider = CGImageGetDataProvider(image.CGImage);
	 CFDataRef imageData = CGDataProviderCopyData(dataProvider);
	 if ([[NSFileManager defaultManager] createFileAtPath:filename contents:(NSData*)imageData attributes:nil] == NO) {
	 NSLog(@"%s, fail to create a file: %@", __func__, filename);
	 }
	 CFRelease(imageData);
	 */
	// TODO: May alternatively write to photo album: UIImageWriteToSavedPhotosAlbum
	//[UIImagePNGRepresentation(image) writeToFile:filename atomically:YES];
	[UIImageJPEGRepresentation(image, 1.0) writeToFile:filename atomically:YES];
	//UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
}

NSString *getThumbnailFilename(NSString *filename) 
{
	NSString *s = nil;
	
	int index = [filename length];
	NSString *ext = [[NSString alloc] initWithString:GEO_IMAGE_EXT];
	
	if (index > 0) {
		s = [[NSString alloc] initWithFormat:@"%@_small%@", [filename substringToIndex:index-[ext length]], GEO_IMAGE_EXT];
	}
	
	[ext release];
	return s;
}

NSString *getThumbnailOldFilename(NSString *filename) 
{
	NSString *s = nil;
	
	int index = [filename length];
	NSString *ext = [[NSString alloc] initWithString:GEO_IMAGE_EXT];
	
	if (index > 0) {
		s = [[NSString alloc] initWithFormat:@"%@_small%@", [filename substringToIndex:index-[ext length]-2], GEO_IMAGE_EXT];
	}
	
	[ext release];
	return s;
}

/* Useless?
NSString *getOrigFilename(NSString *filename)
{
	NSString *s = nil;
	
	int index = [filename length];
	NSString *ext = [[NSString alloc] initWithString:GEO_SMALL_EXT];
	
	if (index > 0) {
		s = [[NSString alloc] initWithFormat:@"%@%@", [filename substringToIndex:index], GEO_IMAGE_EXT];
	}
	
	[ext release];
	
	return s;
}
 */

@implementation NoteViewController

//@synthesize soundFileURLRef;
//@synthesize soundFileObject;
@synthesize addCategoryController;
@synthesize categoryArray;
@synthesize selectedCategory;
@synthesize journalController;
@synthesize defaultCategory;
@synthesize buttonFrame;
@synthesize theTableView;
@synthesize selectedColor;
@synthesize infoButtonImage;
@synthesize selectionImage;
@synthesize currentCategoryLabel;
@synthesize _journalController;
@synthesize _addController;
@synthesize _deleteIndex;
@synthesize buttons;
@synthesize buttonView;
@synthesize labelView;
@synthesize delegate;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
		
		//managedObjectContext = [[GeoDatabase sharedGeoDatabaseInstance] managedObjectContext];
		selectedButton = 0;
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
	
	self.selectionImage = [UIImage imageNamed:@"selection-button.png"];
	self.infoButtonImage = [UIImage imageNamed:@"info-button.png"];
	buttons = [[NSMutableArray alloc] init];
	self.selectedColor = [UIColor colorWithRed:0.4510 green:0.5373 blue:0.6510 alpha:1.0];
	
	NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"DefaultCategory" ofType:@"plist"];
	defaultCategory = [[NSArray alloc] initWithContentsOfFile:thePath];
	
	self.addCategoryController = nil;
	
	[self loadFromDatabase];
	[self setNormalButtons];
	[self initCategoryButtons];
	//[self showSelectedButton];
	// Init scroll view
	//[self setScrollViewSize];
		
	/*
	CFBundleRef mainBundle;
	mainBundle = CFBundleGetMainBundle ();
	
	// Get the URL to the sound file to play
	§Ω
	soundFileURLRef  =	CFBundleCopyResourceURL (
												 mainBundle,
												 CFSTR ("bringup"),
												 CFSTR ("aif"),
												 NULL
												 );
	*/
	// Create a system sound object representing the sound file
	/*
	AudioServicesCreateSystemSoundID (
									  soundFileURLRef,
									  &soundFileObject
									  );
	 */
	//self.tabBarController.tabBar.selectedItem.title = @"Journal";
	self.navigationItem.title = @"Edit Category";
	//[self.buttonFrame setExclusiveTouch:YES];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.contentSizeForViewInPopover = CGSizeMake(310.0, self.theTableView.rowHeight*(self.numberOfCategory+1));
        DEBUG_SIZE("category size:", self.contentSizeForViewInPopover);
        DEBUG_RECT("table view:", self.theTableView.frame);
    }
	//self.buttonFrame.noteDelegate = self;
}

- (void)loadFromDatabase
{
	// Load from the category database
	self.categoryArray = [GeoDatabase sharedGeoDatabaseInstance].categoryArray;
	
	[self verifyDefaultCategories];	
}

- (void)verifyDefaultCategories
{
	DefaultCategory *dc = nil;
	
	// only do that for the first run. And what to do for the already installed user.
    // CTODO: if there is anything in the cloude, what to do with it???
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
        [[GeoDefaults sharedGeoDefaultsInstance] dbInitDone];
	}
}

- (void)setScrollViewSize
{
	// TODO: come up with right scroll view size.
	
	buttonFrame.contentSize = CGSizeMake((BUTTON_WIDTH+BUTTON_MARGIN)*self.numberOfCategory, BUTTON_SCROLL_HEIGHT); //CGSizeMake(buttonFrame.frame.size.width * [defaultCateogry count], 20.0);
	buttonFrame.showsHorizontalScrollIndicator = NO;
    buttonFrame.showsVerticalScrollIndicator = NO;
    buttonFrame.scrollsToTop = NO;	
}

- (void)setNormalButtons
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editCategory)];
        
        self.navigationItem.leftBarButtonItem = editButton;
        [editButton release]; //[addButton release];
    
    }
}

- (void)openTakeJournal:(id)sender
{
	//AudioServicesPlaySystemSound (self.soundFileObject);
	
	GeoTakeController *section = [[GeoTakeController alloc] initWithNibName:@"GeoTake" bundle:nil];
	//[sevc setDelegate:self];
	section.selectedCategory = selectedButton;
	UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:section];

	self.journalController = section;
	[section release];
	//nc.navigationBar.backgroundColor = [UIColor blueColor];
	// Navigation Bar on top
	section.titleForJournal = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
	nc.navigationBar.tintColor = [UIColor colorWithRed:0.0286 green:0.6062 blue:0.3575 alpha:1.0]; // green
	//nc.navigationBar.tintColor = [UIColor colorWithRed:0.6745 green:0.1020 blue:0.1529 alpha:1.0]; // read
	//nc.navigationBar.tintColor = [UIColor colorWithRed:1.0 green:0.97 blue:0.60 alpha:1.0]; // yellow

	[self.navigationController presentModalViewController:nc animated:YES];
	[nc release];		
}

#pragma mark SCROLLABLE BUTTON 
- (void)selectButtonWithIndex:(NSInteger)index
{	
	UIButton *button = [buttons objectAtIndex:index];
	self.selectedCategory = [self.categoryArray objectAtIndex:selectedButton];

	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
	[button setBackgroundImage:selectionImage forState:UIControlStateDisabled];
	self.selectedCategory = [self getCategory:button.currentTitle withIndex:index];
	[GeoDefaults sharedGeoDefaultsInstance].activeCategory = button.currentTitle;
}

- (void)scrollToButton:(NSInteger)index
{
	CGRect rect = CGRectMake((BUTTON_WIDTH+BUTTON_MARGIN)*index, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT);
	
	[self.buttonFrame scrollRectToVisible:rect animated:YES];
	TRACE("%s, %d, %f\n", __func__, index, rect.origin.x);
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
	}
	
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

- (void)selectButton:(NSSet*)touches
{	
	int i = 0;
	float x = 0.0;
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self.buttonFrame];
	
	TRACE("%s, touch: x: %f\n", __func__, touchPoint.x);
	for (UIButton *button in buttons) {
		if (touchPoint.x >= x && touchPoint.x <= x+BUTTON_WIDTH) {
			// user selects this button
			[button setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
			[button setBackgroundImage:selectionImage forState:UIControlStateDisabled];
			selectedButton = i;
			self.selectedCategory = [self getCategory:button.currentTitle withIndex:i];
			[self showSelectedCategory:button.currentTitle];
			[GeoDefaults sharedGeoDefaultsInstance].activeCategory = button.currentTitle;
		}
		else {
			[button setTitleColor:selectedColor forState:UIControlStateDisabled];
			[button setBackgroundImage:nil forState:UIControlStateDisabled];
		}
		++i;
		x += BUTTON_WIDTH;
	}
	
}

/*
 * TODO: Buttons inside scrollview. 
 *   Key: Button is enabled, but doesn't process scroll events.
 */
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
#pragma mark -

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


- (void)selectCategory
{
	//UIButton *selectedButton = nil
	TRACE("%s\n", __func__);
	int i = 0;
	for (UIButton *button in buttons) {
		if (button.touchInside == YES) {
			[button setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
			[button setBackgroundImage:selectionImage forState:UIControlStateDisabled];
			selectedButton = i;
			self.selectedCategory = [self getCategory:button.currentTitle withIndex:i];
			[self showSelectedCategory:button.currentTitle];
			[GeoDefaults sharedGeoDefaultsInstance].activeCategory = button.currentTitle;
		}
		else {
			[button setTitleColor:selectedColor forState:UIControlStateDisabled];
			[button setBackgroundImage:nil forState:UIControlStateDisabled];
		}
		++i;
	}
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
	
	[self showSelectedCategory:button.currentTitle];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
	[button setBackgroundImage:selectionImage forState:UIControlStateDisabled];
}

- (void)showSelectedCategory:(NSString*)text
{
	NSString *s = [[NSString alloc] initWithFormat:@"Selected category: %@", text];
	self.currentCategoryLabel.text = s;
	[s release];
}

- (void)dragToLeft
{
	TRACE("%s\n", __func__);
	//CGRect test = CGRectMake(-100, 4, 320, 20);

	//buttonFrame.frame = test;
}

- (void)dragToRight
{
	TRACE("%s\n", __func__);
}

- (void)addCategory
{
}

- (void)doneEditing
{
	[theTableView setEditing:NO animated:NO];
	//[self setNormalButtons];
	[self._journalController setEditNoteButtons];
}

- (void)cancelEditing
{
	[theTableView setEditing:NO animated:NO];
	[self setNormalButtons];
}

- (void)editCategory
{
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
	
	
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.navigationItem.leftBarButtonItem = doneButton;
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        self._journalController.navigationItem.leftBarButtonItem = doneButton;
        self._journalController.navigationItem.rightBarButtonItem = nil;
    }
	//self.navigationItem.leftBarButtonItem = doneButton;
	//self.navigationItem.rightBarButtonItem = nil;
	
	[theTableView setEditing:YES animated:YES];
}

#pragma mark SCROLL EVENT
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	TRACE("%s\n", __func__);	
}

- (void)scrollViewDidScroll:(UIScrollView *)sender 
{
	//TRACE_HERE;
}

#pragma mark TOUCHES EVENTS
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.buttonFrame];
	
	TRACE("%s, x: %f, y: %f\n", __func__, point.x, point.y);
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.buttonFrame];
	
	TRACE("%s, x: %f, y: %f\n", __func__, point.x, point.y);
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.buttonFrame];
	
	TRACE("%s, x: %f, y: %f\n", __func__, point.x, point.y);
	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.buttonFrame];
	
	TRACE("%s, x: %f, y: %f\n", __func__, point.x, point.y);
	
}

#pragma mark UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// TODO: Get the default category and categories from database
	// Define NSArray for default category and fetch from database rest.
	int c = self.numberOfCategory;
	TRACE("%s, %d\n", __func__, c);
	return c+1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	TRACE("%s, section: %d, row: %d\n", __func__, indexPath.section, indexPath.row);
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		// remove this entry from database
		if ([self.categoryArray count] > 1) {
			GCategory *c = [self.categoryArray objectAtIndex:indexPath.row];
			if ([c.contents count] > 0) {
				self._deleteIndex = indexPath;
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Deleting Category" message:@"This category has more than one item. Do you want to delete this category?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil];
				[alert show];
				[alert release];
			}
			else {
				[self deleteFromCategory:indexPath.row];
				[self._journalController removeFromScrollableButtons:indexPath.row];
				[self showSelectedCategory:self._journalController.selectedCategory.name];
				
				[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
			}
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Deleting Category" message:@"You cannot remove this only remaining category. Please add a new category before you removing this category." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	int c = [self.categoryArray count];
	
	if (indexPath.row == self.numberOfCategory) {
		// Add more category
		AddCategory *controller = [[AddCategory alloc] initWithNibName:@"AddCategory" bundle:nil];
		controller.hidesBottomBarWhenPushed = YES;
		[GeoDefaults sharedGeoDefaultsInstance].secondLevel = self.numberOfCategory;
		TRACE("%s, %p\n", __func__, self.navigationController);
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [self.navigationController pushViewController:controller animated:YES];
        }
        else {
            [self._journalController.navigationController pushViewController:controller animated:YES];
        }
		self.addCategoryController = controller; 
		[controller release];
	}
	else if (indexPath.row < c) {
		GCategory *category = [categoryArray objectAtIndex:indexPath.row];
		[GeoDefaults sharedGeoDefaultsInstance].activeCategory = category.name;
		[self showSelectedCategory:category.name];
		[tableView reloadData];
        
        [self.delegate setCategory:category.name];
	}
	/*
	else if (indexPath.row < c) {
		if (self._journalController == nil) {
			JournalViewController *journalViewController = [[JournalViewController alloc] initWithNibName:@"JournalViewController" bundle:nil];
			self._journalController = journalViewController;
			[journalViewController release];
		}
		else {
			self._journalController.isCategoryChanged = YES;
		}
		//journalViewController.hidesBottomBarWhenPushed = YES;
		self._journalController.selectedCategory = [self.categoryArray objectAtIndex:indexPath.row];
		//[GeoDefaults sharedGeoDefaultsInstance].secondLevel = indexPath.row;
		//[self.navigationController pushViewController:self._journalController animated:YES];
		[self showSelectedCategory:self._journalController.selectedCategory.name];
	}
	else 
	{
		NSLog(@"%s, index error: %d", __func__, indexPath.row);
		//journalViewController.selectedCategory = [self.categoryArray objectAtIndex:indexPath.row-c];
		//[self.navigationController pushViewController:journalViewController animated:YES];
	}
	 */
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// TODO: need to define table cells.
	TRACE("%s, section: %d, row: %d\n", __func__, indexPath.section, indexPath.row);
	NSString* identity = @"CategoryCell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identity];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identity] autorelease];
	}
	
	int c = [self.categoryArray count]; //[defaultCategory count];
	if (indexPath.row < c) {
		GCategory *c = (GCategory*) [self.categoryArray objectAtIndex:indexPath.row];
		//cell.textLabel.text = c.name;
		
		UILabel *textLabel = (UILabel*) [cell.contentView viewWithTag:JOURNAL_CONTENT_VIEW_TAG];
		[textLabel retain];
		if (textLabel == nil) {
			textLabel = [[UILabel alloc] initWithFrame:CGRectMake(GEO_TITLE_RECT_X, GEO_TITLE_RECT_Y, GEO_TITLE_RECT_WIDTH, GEO_TITLE_RECT_HEIGHT)];
			textLabel.tag = JOURNAL_CONTENT_VIEW_TAG;
			textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
			textLabel.textColor = [UIColor blackColor]; //[UIColor colorWithRed:0.23 green:0.35 blue:0.60 alpha:1.0]; //
		}
		
		textLabel.text = c.name;
		[cell.contentView addSubview:textLabel];
		[textLabel release];
		
		UIButton *infoButton = (UIButton*) [cell.contentView viewWithTag:JOURNAL_INFO_BUTTON_TAG];
		if (infoButton == nil) {
			infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
			
			[infoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
			[infoButton addTarget:self action:@selector(selectCategory) forControlEvents:UIControlEventTouchDown]; 
			//[button addTarget:self action:@selector(dragToLeft) forControlEvents:UIControlEventTouchDragInside];
			//[button addTarget:self action:@selector(dragToRight) forControlEvents:UIControlEventTouchDragOutside];
			infoButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12];
			//button.showsTouchWhenHighlighted = YES;
			[infoButton setBackgroundImage:infoButtonImage forState:UIControlStateNormal];
			infoButton.hidden = NO;
			infoButton.frame = CGRectMake(GEO_BUTTON_RECT_X, GEO_BUTTON_RECT_Y, GEO_BUTTON_RECT_WIDTH, GEO_BUTTON_RECT_HEIGHT);
			infoButton.userInteractionEnabled = NO;
			infoButton.tag = JOURNAL_INFO_BUTTON_TAG;
		}
		
		NSString *countInfo = [[NSString alloc] initWithFormat:@"%d", [c.contents count]];
		[infoButton setTitle:countInfo forState:UIControlStateNormal];
		
		[cell.contentView addSubview:infoButton];
		[countInfo release];
		if ([textLabel.text compare:[GeoDefaults sharedGeoDefaultsInstance].activeCategory] == NSOrderedSame) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			self._journalController.isCategoryChanged = YES;
			self._journalController.selectedCategory = [self getCategory:textLabel.text];
		}
		else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	/*
	else if (indexPath.row < [categoryArray count]) {
		GCategory *category = (GCategory*)[categoryArray objectAtIndex:indexPath.row];
		cell.textLabel.text = category.name;
	}
	 */
	else if (indexPath.row == c) {
		UILabel *textLabel = (UILabel*) [cell.contentView viewWithTag:JOURNAL_CONTENT_VIEW_TAG];
		[textLabel retain];
		if (textLabel == nil) {
			textLabel = [[UILabel alloc] initWithFrame:CGRectMake(GEO_TITLE_RECT_X, GEO_TITLE_RECT_Y, GEO_TITLE_RECT_WIDTH, GEO_TITLE_RECT_HEIGHT)];
			textLabel.tag = JOURNAL_CONTENT_VIEW_TAG;
			textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
			textLabel.textColor = [UIColor blackColor]; //[UIColor colorWithRed:0.23 green:0.35 blue:0.60 alpha:1.0]; //[UIColor blackColor];
		}
		
		textLabel.text = ADD_CATEGORY_TEXT;

		[cell.contentView addSubview:textLabel];
		[textLabel release];
		
		UIButton *infoButton = (UIButton*) [cell.contentView viewWithTag:JOURNAL_INFO_BUTTON_TAG];
		if (infoButton) {
			[infoButton removeFromSuperview];
		}
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else {
		NSLog(@"%s, index error: %d", __func__, indexPath.row);
	}
	
	
	
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	TRACE_HERE;
	BOOL editable = YES;
		
	if (self.theTableView.editing == YES) {
		if (indexPath.row < [self.categoryArray count]) {
			editable = YES;
		}
	}
	return editable;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	TRACE_HERE;
	UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;

	if (self.theTableView.editing == YES) {
		if (indexPath.row < [self.categoryArray count]) {
			style = UITableViewCellEditingStyleDelete;
		}
	}
	
	return style;
}

#pragma mark UIAlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0:
			break;
		case 1:
			if (self._deleteIndex) {
				[self deleteFromCategory:self._deleteIndex.row];
				[self._journalController removeFromScrollableButtons:self._deleteIndex.row];
				[self showSelectedCategory:self._journalController.selectedCategory.name];
			
				[self.theTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:self._deleteIndex] withRowAnimation:YES];
			}
			break;
		default:
			break;
	}
}
#pragma mark -

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

- (void)viewDidAppear:(BOOL)animated
{    
    UITabBar *tabBar = self.tabBarController.tabBar;
    
    TRACE("%s, %p, %s\n", __func__, tabBar.selectedItem, [tabBar.selectedItem.title UTF8String]);
    
    
    if (addCategoryController && addCategoryController.saveResult == YES) {
        TRACE("%s\n", __func__);
        
        [self saveCategory];
        [theTableView reloadData];
        addCategoryController.saveResult = NO;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.contentSizeForViewInPopover = CGSizeMake(310.0, self.theTableView.rowHeight*(self.numberOfCategory+1));
            DEBUG_SIZE("category size:", self.contentSizeForViewInPopover);
            DEBUG_RECT("table view:", self.theTableView.frame);
        }
    }
    else if (journalController && journalController.journalTaken == JOURNAL_TAKEN) {
        // save journal to category.
        if (journalController.myPicture && journalController.pictureView.image) {
            saveImageToFile(journalController.pictureView.image, journalController.myPicture);
            NSString *smallImage = getThumbnailFilename(journalController.myPicture);
            saveImageToFile(journalController.thumbnailImage, smallImage);
            [smallImage release];
        }
        journalController.journalTaken = NO;
        [self saveJournalToDatabase];
        
        [theTableView reloadData];
    }
    else if (journalController && journalController.journalTaken == JOURNAL_CANCELLED) {
        // Should delay destorying controller due to the delegate need to be live longer.
        //self.journalController = nil;
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
        if ([GeoDefaults sharedGeoDefaultsInstance].levelRestored == NO) {
            [self restoreLevel];
        }
        else {
            [GeoDefaults sharedGeoDefaultsInstance].secondLevel = -1;
            [theTableView reloadData];
        }
        [self scrollToButton:selectedButton];
    }
    
}

- (void)restoreLevel
{
	int index = [GeoDefaults sharedGeoDefaultsInstance].secondLevel;
	
	if (index > -1) {
		if (index == self.numberOfCategory) {
			// Add more category
			AddCategory *controller = [[AddCategory alloc] initWithNibName:@"AddCategory" bundle:nil];
			controller.hidesBottomBarWhenPushed = YES;
			[self.navigationController pushViewController:controller animated:NO];
			self.addCategoryController = controller;
			[controller release];
		}
		else if (index < self.numberOfCategory) {
			if (self._journalController == nil) {
				JournalViewController *journalViewController = [[JournalViewController alloc] initWithNibName:@"JournalViewController" bundle:nil];
				self._journalController = journalViewController;
				[journalViewController release];
			}
			self._journalController.selectedCategory = [self.categoryArray objectAtIndex:index];
			[self.navigationController pushViewController:self._journalController animated:NO];
		}
	}	
	[GeoDefaults sharedGeoDefaultsInstance].levelRestored = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
	
}

- (void)deleteFromCategory:(NSInteger)index
{
	NSManagedObject *categoryToDelete = [self.categoryArray objectAtIndex:index];
	[[GeoDatabase sharedGeoDatabaseInstance] deleteObject:categoryToDelete];
	//[managedObjectContext deleteObject:categoryToDelete];
	
	// Update the array and table view.
	[self.categoryArray removeObjectAtIndex:index];
	
	// Commit the change.
	[[GeoDatabase sharedGeoDatabaseInstance] save];
}

- (void)saveCategory
{
	GCategory *category = [GeoDatabase sharedGeoDatabaseInstance].categoryEntity;
	
	if ([addCategoryController.textInputField.text length] > 0) {
		[category setName:addCategoryController.textInputField.text];
		[category setCreationDate:[NSDate date]];

		[[GeoDatabase sharedGeoDatabaseInstance] save];
		[self.categoryArray addObject:category];
		
		// Add to the scroll view
		[self._journalController addNewScrollableButton:addCategoryController.textInputField.text];
	}
}

- (void)adjustOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    CGRect bounds = self.view.bounds;
    
    CGRect frame = CGRectMake(self.buttonView.frame.origin.x, self.buttonView.frame.origin.y, 
                              bounds.size.width, self.buttonView.frame.size.height);
    self.buttonView.frame = frame;
    DEBUG_RECT("buttonview:", self.buttonView.frame);
    self.buttonFrame.frame = frame;
    DEBUG_RECT("buttonframe:", self.buttonFrame.frame);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    CGRect bounds = self.view.bounds;
    
    DEBUG_RECT("bound:", bounds);
}

/*
#pragma mark Data Picker Delegates

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	//ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	return 1;//[storage numberOfFeedSections];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return 2;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	return 200.0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return @"test";
}

*/

#pragma mark -
#pragma mark Helpers

- (NSInteger)numberOfCategory
{
	return [self.categoryArray count];
}

#pragma mark Memory Management
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
	TRACE_HERE;
	[buttons removeAllObjects];
	
	self.addCategoryController = nil;
	self.selectedCategory = nil;
	self.journalController = nil;
	self.defaultCategory = nil;
	self.buttonFrame = nil;
	self.theTableView = nil;
	self.currentCategoryLabel = nil;
	
	self.selectionImage = nil;
	self.infoButtonImage = nil;
	self.buttons = nil;
	self.selectedColor = nil;
    self.buttonView = nil;
}


- (void)dealloc {
	TRACE_HERE;
	//[managedObjectContext release];
	[_deleteIndex release];
	[_addController release];
	[_journalController release];
	[addCategoryController release];
	[buttons release];
	[categoryArray release];
	[selectedCategory release];
	[journalController release];
	[defaultCategory release];
	[buttonFrame release];
	[theTableView release];
	[selectedColor release];
	[infoButtonImage release];
	[selectionImage release];
	[currentCategoryLabel release];
    [buttonView release];
	
    [super dealloc];
	
	//AudioServicesDisposeSystemSoundID (self.soundFileObject);
	//CFRelease (soundFileURLRef);

}


@end
