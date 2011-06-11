//
//  GeoDefaults.m
//  GeoJournal
//
//  Created by Jae Han on 7/9/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "GeoDefaults.h"
#import "GeoJournalHeaders.h"

// Degining default database keys.
#define kNumberOfFileGeneragedKey	@"NUMBER_OF_FILE_GENERATED"
#define kActiveCategoryKey			@"ACTIVE_CATEGORY"
#define kTestJournalCreatedKey		@"TEST_JOURNAL_CREATED"
#define kMapTypeKey					@"MAP_TYPE"
#define	kCategoryTypeKey			@"CATEGORY_KEY"
#define kNumLocationKey				@"NUM_LOCATION_KEY"
#define kMapSlideShowIntervalKey	@"MAP_SLIDESHOW_INTERVAL"
//
#define GEO_FOLDER_NAME				@"GeoJournal"
#define GEO_FILE_EXT				@".geo"

static GeoDefaults	*sharedGeoDefaults = nil;

@implementation GeoDefaults

@synthesize numberOfFileGenerated;
@synthesize activeCategory;
@synthesize geoDocumentPath;
@synthesize applicationDocumentsDirectory;
@synthesize testJournalCreated;
@synthesize mapType;
@synthesize categoryType;
@synthesize numLocation;
@synthesize mapSlideShowInterval;

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
	[numberOfFileGenerated release];
	[activeCategory release];
	[applicationDocumentsDirectory release];
	[geoDocumentPath release];
	[testJournalCreated release];
	[mapType release];
	[categoryType release];
	[numLocation release];
	[mapSlideShowInterval release];

	[super dealloc];
}

#pragma mark Implementation
-(void)initDefaultSettings
{
	srandom(time(NULL));
	
	
	self.numberOfFileGenerated = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kNumberOfFileGeneragedKey];
	if (self.numberOfFileGenerated == nil) {
		NSNumber *temp = [[NSNumber alloc] initWithInt:0];
		self.numberOfFileGenerated = temp; [temp release];
		NSString *s = [[NSString alloc] initWithString:NO_ACTIVE_CATEGORY];
		self.activeCategory = s; [s release];
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
		// Has not been created, create one.
		
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
										numberOfFileGenerated, kNumberOfFileGeneragedKey,
										activeCategory, kActiveCategoryKey,
										testJournalCreated, kTestJournalCreatedKey,
										mapType, kMapTypeKey,
										categoryType, kCategoryTypeKey,
										numLocation, kNumLocationKey,
									 mapSlideShowInterval, kMapSlideShowIntervalKey,
									 nil];
		[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	self.numberOfFileGenerated = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kNumberOfFileGeneragedKey];
	self.activeCategory = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:kActiveCategoryKey];
	self.testJournalCreated = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kTestJournalCreatedKey];
	self.mapType = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kMapTypeKey];
	self.categoryType = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kCategoryTypeKey];
	self.numLocation = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kNumLocationKey];
	self.mapSlideShowInterval = (NSNumber*) [[NSUserDefaults standardUserDefaults] objectForKey:kMapSlideShowIntervalKey];
	
	applicationDocumentsDirectory = nil;
	geoDocumentPath = nil;
	fileManager = [NSFileManager defaultManager];
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

- (void)saveDefaultSettings
{
	TRACE("%s, %s\n", __func__, [activeCategory UTF8String]);
	[[NSUserDefaults standardUserDefaults] setObject:numberOfFileGenerated forKey:kNumberOfFileGeneragedKey];
	[[NSUserDefaults standardUserDefaults] setObject:activeCategory forKey:kActiveCategoryKey];
	[[NSUserDefaults standardUserDefaults] setObject:testJournalCreated forKey:kTestJournalCreatedKey];
	[self saveMapSettins];
}

#pragma mark SETTING VARIABLES

- (void)saveMapSettins
{
	[[NSUserDefaults standardUserDefaults] setObject:mapType forKey:kMapTypeKey];
	[[NSUserDefaults standardUserDefaults] setObject:categoryType forKey:kCategoryTypeKey];
	[[NSUserDefaults standardUserDefaults] setObject:numLocation forKey:kNumLocationKey];
	[[NSUserDefaults standardUserDefaults] setObject:mapSlideShowInterval forKey:kMapSlideShowIntervalKey];
}

#pragma mark -

@end
