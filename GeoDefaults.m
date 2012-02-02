//
//  GeoDefaults.m
//  GeoJournal
//
//  Created by Jae Han on 7/9/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "GeoDefaults.h"
#import "GeoJournalHeaders.h"
#import "KeychainItemWrapper.h"

// Degining default database keys.
#define kNumberOfFileGeneragedKey		@"NUMBER_OF_FILE_GENERATED"
#define kActiveCategoryKey				@"ACTIVE_CATEGORY"
#define kTestJournalCreatedKey			@"TEST_JOURNAL_CREATED"
#define kMapTypeKey						@"MAP_TYPE"
#define	kCategoryTypeKey				@"CATEGORY_KEY"
#define kNumLocationKey					@"NUM_LOCATION_KEY"
#define kMapSlideShowIntervalKey		@"MAP_SLIDESHOW_INTERVAL"
#define kImageSlideShowIntervalKey		@"IMAGE_SLIDESHOW_INTERVAL"
#define kShowSliderKey					@"SHOW_MAP_SLIDER"
#define kImageCategoryTypeKey			@"IMAGE_CATEGORY_TYPE"
#define kImageNumLocationKey			@"IMAGE_LOCATION_TYPE"
#define kShowImageSliderKey				@"SHOW_IMAGE_SLIDER"
#define kCategoryTypeForHorizontalKey	@"CATEGORY_KEY_FOR_HORIZONTAL"
#define kShowSlideshowInHorizontalKey	@"SHOW_SLIDESHOW_IN_HORIZONTAL"
#define kEnableAudioInHorizontalKey		@"EBNABLE_AUDIO_IN_HORIZONTAL"
#define kShowContentInHorizontalKey		@"SHOW_CONTENT_IN_HORIZONTAL"
#define kSliderForHorizontalKey			@"SLIDER_FOR_HORIZONTAL"
#define kSavedLocationKey				@"SAVED_LOCATION"
#define kSearchIndexKey					@"SEARCH_INDEX"
#define kSearchStringKey				@"SEARCH_STRING"
#define kDefaultFontSizeKey				@"DEFAULT_FONT_SIZE"
#define kDefaultInitDoneKey				@"DEFAULT_INIT_DONE"
#define kIsPriviateKey                  @"IS_PRIVATE"

//
#define GEO_FOLDER_NAME				@"GeoJournal"
#define GEO_FILE_EXT				@".geo"

static GeoDefaults	*sharedGeoDefaults = nil;

@implementation GeoDefaults

@synthesize searchIndex;
@synthesize searchString;
@synthesize savedLocation;
@synthesize sliderForHorizontal;
@synthesize numberOfFileGenerated;
@synthesize activeCategory;
@synthesize geoDocumentPath;
@synthesize applicationDocumentsDirectory;
@synthesize testJournalCreated;
@synthesize mapType;
@synthesize categoryType;
@synthesize numLocation;
@synthesize mapSlideShowInterval;
@synthesize imageSlideShowInterval;
@synthesize showSlider;
@synthesize imageCategoryType;
@synthesize imageNumLocation;
@synthesize showImageSlider;
@synthesize categoryTypeForHorizontal;
@synthesize showSlideshowInHorizontal;
@synthesize enableAudioInHorizontal;
@synthesize showContentInHorizontal;
@synthesize levelRestored;
@synthesize defaultFontSize;
@synthesize defaultInitDone;
@synthesize isPrivate;
@synthesize passwordItem;

int getNumberFromIndex(int i)
{
	int ret = -1;
	switch (i) {
		case 0:
			ret = 5;
			break;
		case 1:
			ret = 10;
			break;
		case 2:
			ret = 20;
			break;
		default:
			ret = -1;
			break;
	}
	
	return ret;
}

+ (GeoDefaults*)sharedGeoDefaultsInstance
{
	//@synchronized (self) {
	if (sharedGeoDefaults == nil) {
		[[self alloc] init];
	}
	//}
	return sharedGeoDefaults;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized (self) { 
		if (sharedGeoDefaults == nil) { 
			sharedGeoDefaults = [super allocWithZone:zone]; 
			return sharedGeoDefaults;
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

-(id)init 
{
	self = [super init];
	if (self) {
		[self initDefaultSettings];
	}
	
	return self;
}

- (void)dealloc 
{
	[searchIndex release];
	[searchString release];
	[savedLocation release];
	[numberOfFileGenerated release];
	[activeCategory release];
	[applicationDocumentsDirectory release];
	[geoDocumentPath release];
	[testJournalCreated release];
	[mapType release];
	[categoryType release];
	[numLocation release];
	[mapSlideShowInterval release];
	[imageSlideShowInterval release];
	[showSlider release];
	[imageCategoryType release];
	[imageNumLocation release];
	[showImageSlider release];
	[defaultFontSize release];
	[defaultInitDone release];
    [isPrivate release];
    [passwordItem release];

	[super dealloc];
}

#pragma mark Implementation
-(void)initDefaultSettings
{
	srandom(time(NULL));
	NSDictionary *appDefaults = nil;
	
	self.numberOfFileGenerated = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kNumberOfFileGeneragedKey];
	if (self.numberOfFileGenerated == nil) {
		NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"DefaultCategory" ofType:@"plist"];
		NSArray *defaultCategory = [[NSArray alloc] initWithContentsOfFile:thePath];
		
		NSNumber *temp = [[NSNumber alloc] initWithInt:0];
		self.numberOfFileGenerated = temp; [temp release];
		NSString *s = [[NSString alloc] initWithString:[defaultCategory objectAtIndex:0]];
		self.activeCategory = s; [s release]; [defaultCategory release];
		temp = [[NSNumber alloc] initWithBool:NO];
		self.testJournalCreated = temp; [temp release];
		temp = [[NSNumber alloc] initWithInt:0];
		self.mapType = temp; [temp release];
		temp = [[NSNumber alloc] initWithInt:0];
		self.categoryType = temp; [temp release];
		temp = [[NSNumber alloc] initWithInt:1];
		self.numLocation = temp; [temp release];
		temp = [[NSNumber alloc] initWithInt:3];
		self.mapSlideShowInterval =temp; [temp release];
		temp = [[NSNumber alloc] initWithInt:3];
		self.imageSlideShowInterval = temp; [temp release];
		temp = [[NSNumber alloc] initWithBool:YES];
		self.showSlider = temp; [temp release];
		temp = [[NSNumber alloc] initWithInt:0];
		self.imageCategoryType = temp; [temp release];
		temp = [[NSNumber alloc] initWithInt:3];
		self.imageNumLocation = temp; [temp release];
		temp = [[NSNumber alloc] initWithBool:YES];
		self.showImageSlider = temp; [temp release];
		temp = [[NSNumber alloc] initWithInt:1];
		self.categoryTypeForHorizontal = temp; [temp release];
		temp = [[NSNumber alloc] initWithBool:YES];
		self.showSlideshowInHorizontal = temp; [temp release];
		temp = [[NSNumber alloc] initWithBool:YES];
		self.enableAudioInHorizontal = temp; [temp release];
		temp = [[NSNumber alloc] initWithBool:YES];
		self.showContentInHorizontal = temp; [temp release];
		temp = [[NSNumber alloc] initWithInt:3];
		self.sliderForHorizontal = temp; [temp release];
		temp = [[NSNumber alloc] initWithInt:DEFAULT_FONT_SIZE];
		self.defaultFontSize = temp; [temp release];
		temp = [[NSNumber alloc] initWithInt:0];
		self.defaultInitDone = temp; [temp release];
        temp = [[NSNumber alloc] initWithInt:1];
        self.isPrivate = temp;
		
		// TODO: it must to be retained. Why???
		NSMutableArray *loc = [[NSMutableArray arrayWithObjects:
											   [NSNumber numberWithInteger:-1],	// item selection at 1st level (-1 = no selection)
											   [NSNumber numberWithInteger:-1],	// .. 2nd level
											   [NSNumber numberWithInteger:-1],	// .. 3rd level
											   nil] retain];
		self.savedLocation = loc; [loc release];
		temp = [[NSNumber alloc] initWithInt:0];
		self.searchIndex = temp; [temp release];
		s = [[NSString alloc] init];
		self.searchString = s; [s release];
		
		// No need to restore levels.
		levelRestored = YES;
	}
	else {
	
		// General
		self.numberOfFileGenerated = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kNumberOfFileGeneragedKey];
		self.activeCategory = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:kActiveCategoryKey];
		self.testJournalCreated = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kTestJournalCreatedKey];
		// For map
		self.mapType = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kMapTypeKey];
		self.categoryType = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kCategoryTypeKey];
		self.numLocation = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kNumLocationKey];
		self.mapSlideShowInterval = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kMapSlideShowIntervalKey];
		self.showSlider = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kShowSliderKey];
		// For slideshow
		self.imageSlideShowInterval = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kImageSlideShowIntervalKey];
		self.imageCategoryType = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kImageCategoryTypeKey];
		self.imageNumLocation = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kImageNumLocationKey];
		self.showImageSlider = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kShowImageSliderKey];
		// For horizontal slideshow
		self.categoryTypeForHorizontal = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kCategoryTypeForHorizontalKey];
		self.showSlideshowInHorizontal = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kShowSlideshowInHorizontalKey];
		self.enableAudioInHorizontal = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kEnableAudioInHorizontalKey];
		self.showContentInHorizontal = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kShowContentInHorizontalKey];
		self.sliderForHorizontal = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kSliderForHorizontalKey];
		
		// Where were we last time?
		NSMutableArray *tempArray = [[[NSUserDefaults standardUserDefaults] objectForKey:kSavedLocationKey] mutableCopy];
		self.savedLocation = tempArray; [tempArray release];
		
		// For search
		self.searchIndex = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kSearchIndexKey];
		self.searchString = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:kSearchStringKey];
		
		// For the font size
		self.defaultFontSize = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultFontSizeKey];
		
		// Default category initialized
		self.defaultInitDone = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultInitDoneKey];
		self.isPrivate = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kIsPriviateKey];
        
		// will need to restore levels
		levelRestored = NO;
	}
	
	appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
				   numberOfFileGenerated, kNumberOfFileGeneragedKey,
				   activeCategory, kActiveCategoryKey,
				   testJournalCreated, kTestJournalCreatedKey,
				   mapType, kMapTypeKey,
				   categoryType, kCategoryTypeKey,
				   numLocation, kNumLocationKey,
				   mapSlideShowInterval, kMapSlideShowIntervalKey,
				   showSlider, kShowSliderKey,
				   imageCategoryType, kImageCategoryTypeKey,
				   imageNumLocation, kImageNumLocationKey,
				   showImageSlider, kShowImageSliderKey,
				   imageSlideShowInterval, kImageSlideShowIntervalKey,
				   categoryTypeForHorizontal, kCategoryTypeForHorizontalKey,
				   showSlideshowInHorizontal, kShowSlideshowInHorizontalKey,
				   enableAudioInHorizontal, kEnableAudioInHorizontalKey,
				   showContentInHorizontal, kShowContentInHorizontalKey,
				   sliderForHorizontal, kSliderForHorizontalKey,
				   savedLocation, kSavedLocationKey,
				   searchIndex, kSearchIndexKey,
				   searchString, kSearchStringKey,
				   defaultFontSize, kDefaultFontSizeKey,
				   defaultInitDone, kDefaultInitDoneKey,
                   isPrivate, kIsPriviateKey,
				   nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
	[[NSUserDefaults standardUserDefaults] synchronize];

	applicationDocumentsDirectory = nil;
	geoDocumentPath = nil;
	fileManager = [NSFileManager defaultManager];
    
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"Password" accessGroup:nil];
	self.passwordItem = wrapper;
    [wrapper release];

}

#pragma mark -
#pragma mark Application's documents directory

- (NSString *)applicationDocumentsDirectory {
	if (applicationDocumentsDirectory == nil) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		self.applicationDocumentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	}
    return applicationDocumentsDirectory;
}

- (NSString *)geoDocumentPath {
	NSError *error = nil;
	if (geoDocumentPath == nil) {
		self.geoDocumentPath = [applicationDocumentsDirectory stringByAppendingPathComponent:GEO_FOLDER_NAME];
		if ([fileManager fileExistsAtPath:geoDocumentPath] == NO) {
			if ([fileManager createDirectoryAtPath:geoDocumentPath withIntermediateDirectories:YES attributes:nil error:&error] == NO) {
				NSLog(@"%s, %@", __func__, error);
			}
		}
		NSLog(@"%s, document path: %@", __func__, geoDocumentPath);
	}
	return geoDocumentPath;
}

- (NSString*)getUniqueFilenameWithExt:(NSString*)ext 
{
	NSString *e = (ext==nil?GEO_FILE_EXT:ext);
	NSString *str =  [[NSString alloc] initWithFormat:@"%d%@", random(), e];
	NSInteger i = [numberOfFileGenerated intValue];
	NSNumber *n = [[NSNumber alloc] initWithInt:i+1];
	self.numberOfFileGenerated = n;
	[n release];
	
	NSString *path = [self.geoDocumentPath stringByAppendingPathComponent:str];
	[str release];
	return path;
}

- (NSString*)getAbsoluteDocPath:(NSString*)lastComponent
{
	NSString *path = nil;
	
	if (lastComponent) {
		path = [self.geoDocumentPath stringByAppendingPathComponent:lastComponent];
	}
	return path;
}

#pragma mark LEVEL SETTINGS

- (NSInteger)firstLevel 
{
	return [[self.savedLocation objectAtIndex:0] integerValue];
}

- (NSInteger)secondLevel
{
	return [[self.savedLocation objectAtIndex:1] integerValue];
}

- (NSInteger)thirdLevel
{
	return [[self.savedLocation objectAtIndex:2] integerValue];
}

- (void)setFirstLevel:(NSInteger)value
{
	//TRACE("%s, %d\n", __func__, value);
	[self.savedLocation replaceObjectAtIndex:0 withObject:[NSNumber numberWithInt:value]];
}

- (void)setSecondLevel:(NSInteger)value
{
	//TRACE("%s, %d\n", __func__, value);
	[self.savedLocation replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:value]];	
}

- (void)setThirdLevel:(NSInteger)value
{
	//TRACE("%s, %d\n", __func__, value);
	[self.savedLocation replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:value]];
}

#pragma mark -
#pragma mark SETTING VARIABLES

- (BOOL)needRefreshCategory:(NSString*)category 
{
	BOOL v = YES;

	if ((category != nil) && ([category compare:self.activeCategory] == NSOrderedSame)) {
		v = NO;
	}
	
	return v;
}

- (void)saveDefaultSettings
{
	NSNumber *initDone = [[NSNumber alloc] initWithInt:1];
	self.defaultInitDone = initDone;
	[initDone release];
	
	TRACE("%s, %s\n", __func__, [activeCategory UTF8String]);
	[[NSUserDefaults standardUserDefaults] setObject:savedLocation forKey:kSavedLocationKey];
	[[NSUserDefaults standardUserDefaults] setObject:numberOfFileGenerated forKey:kNumberOfFileGeneragedKey];
	[[NSUserDefaults standardUserDefaults] setObject:activeCategory forKey:kActiveCategoryKey];
	[[NSUserDefaults standardUserDefaults] setObject:testJournalCreated forKey:kTestJournalCreatedKey];
	[[NSUserDefaults standardUserDefaults] setObject:defaultInitDone forKey:kDefaultInitDoneKey];
	[self saveMapSettins];
	[self saveImageSlideshowSettings];
	[self saveHorizontalSlideshowSettings];
	[self saveFontSize];
    [[NSUserDefaults standardUserDefaults] setObject:isPrivate forKey:kIsPriviateKey];
}

- (void)saveMapSettins
{
	[[NSUserDefaults standardUserDefaults] setObject:mapType forKey:kMapTypeKey];
	[[NSUserDefaults standardUserDefaults] setObject:categoryType forKey:kCategoryTypeKey];
	[[NSUserDefaults standardUserDefaults] setObject:numLocation forKey:kNumLocationKey];
	[[NSUserDefaults standardUserDefaults] setObject:mapSlideShowInterval forKey:kMapSlideShowIntervalKey];
	[[NSUserDefaults standardUserDefaults] setObject:showSlider forKey:kShowSliderKey];
}

- (void)saveImageSlideshowSettings
{
	[[NSUserDefaults standardUserDefaults] setObject:imageSlideShowInterval forKey:kImageSlideShowIntervalKey];
	[[NSUserDefaults standardUserDefaults] setObject:imageCategoryType forKey:kImageCategoryTypeKey];
	[[NSUserDefaults standardUserDefaults] setObject:imageNumLocation forKey:kImageNumLocationKey];
	[[NSUserDefaults standardUserDefaults] setObject:showImageSlider forKey:kShowImageSliderKey];
}

- (void)saveHorizontalSlideshowSettings
{
	[[NSUserDefaults standardUserDefaults] setObject:categoryTypeForHorizontal forKey:kCategoryTypeForHorizontalKey];
	[[NSUserDefaults standardUserDefaults] setObject:showSlideshowInHorizontal forKey:kShowSlideshowInHorizontalKey];
	[[NSUserDefaults standardUserDefaults] setObject:enableAudioInHorizontal forKey:kEnableAudioInHorizontalKey];
	[[NSUserDefaults standardUserDefaults] setObject:showContentInHorizontal forKey:kShowContentInHorizontalKey];
	[[NSUserDefaults standardUserDefaults] setObject:sliderForHorizontal forKey:kSliderForHorizontalKey];
}

- (void)saveSerarchSettings
{
	[[NSUserDefaults standardUserDefaults] setObject:searchIndex forKey:kSearchIndexKey];
	[[NSUserDefaults standardUserDefaults] setObject:searchString forKey:kSearchStringKey];
}

- (void)saveFontSize
{
	[[NSUserDefaults standardUserDefaults] setObject:defaultFontSize forKey:kDefaultFontSizeKey];
}

#pragma mark -
#pragma PASSCODE
- (NSInteger)getPasscode
{
    return [[self.passwordItem objectForKey:kSecValueData] intValue];
}

- (void)setPasscode:(NSInteger)passcode
{
    [self.passwordItem setObject:[NSString stringWithFormat:@"%d",passcode] forKey:kSecValueData];
}
#pragma -

@end
