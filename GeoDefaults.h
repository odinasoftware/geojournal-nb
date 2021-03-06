//
//  GeoDefaults.h
//  GeoJournal
//
//  Created by Jae Han on 7/9/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define	NO_ACTIVE_CATEGORY	@"None"
//
#define GEO_FOLDER_NAME				@"GeoJournal"
#define GEO_DB_FOLDER_NAME          @"GeoJournalDB"
#define GEO_FILE_EXT				@".geo"
#define GEO_CLOUD_IDC               @"geojournal_idc_odinasoftware.geo"
#define GEO_LOCAL_DOWNLOAD_IDC      @"geojournal_idc_local_download.geo"
#define GEO_SUPPORT_FOLDER_NAME     @"SUPPORT"

@class KeychainItemWrapper;

@interface GeoDefaults : NSObject {
	NSNumber				*numberOfFileGenerated;
	NSString				*activeCategory;
	NSString				*geoDocumentPath;
	NSString				*applicationDocumentsDirectory;
	NSNumber				*testJournalCreated;
	NSNumber				*mapType;
	NSNumber				*categoryType;
	NSNumber				*numLocation;
	NSNumber				*showSlider;
	NSNumber				*mapSlideShowInterval;
	NSNumber				*imageSlideShowInterval;
	NSNumber				*imageCategoryType;
	NSNumber				*imageNumLocation;
	NSNumber				*showImageSlider;
	NSNumber				*categoryTypeForHorizontal;
	NSNumber				*showSlideshowInHorizontal;
	NSNumber				*enableAudioInHorizontal;
	NSNumber				*showContentInHorizontal;
	NSNumber				*sliderForHorizontal;
	NSNumber				*defaultFontSize;
	NSMutableArray			*savedLocation;
	NSNumber				*searchIndex;
	NSNumber				*defaultInitDone;
    NSNumber                *enableCloud;
    NSNumber                *askCloudQuestion;
	NSString				*searchString;
	NSFileManager			*fileManager;
	BOOL					levelRestored;
    NSNumber                *isPrivate;
    KeychainItemWrapper     *passwordItem;
    
	NSString                *UUID;
    NSNumber                *dbReadyForCloud;
}

@property (nonatomic, retain)	NSMutableArray *savedLocation;
@property (nonatomic, retain)	NSNumber	*sliderForHorizontal;
@property (nonatomic, retain)	NSNumber	*showSlider;
@property (nonatomic, retain)	NSNumber	*numberOfFileGenerated;
@property (nonatomic, retain)	NSString	*activeCategory;
@property (nonatomic, retain)	NSString	*applicationDocumentsDirectory;
@property (nonatomic, retain)	NSString	*geoDocumentPath;
@property (nonatomic, retain)	NSNumber	*testJournalCreated;
@property (nonatomic, retain)	NSNumber	*mapType;
@property (nonatomic, retain)	NSNumber	*categoryType;
@property (nonatomic, retain)	NSNumber	*numLocation;
@property (nonatomic, retain)	NSNumber	*mapSlideShowInterval;
@property (nonatomic, retain)	NSNumber	*imageSlideShowInterval;
@property (nonatomic, retain)	NSNumber	*imageCategoryType;
@property (nonatomic, retain)	NSNumber	*imageNumLocation;
@property (nonatomic, retain)	NSNumber	*showImageSlider;
@property (nonatomic, retain)	NSNumber	*categoryTypeForHorizontal;
@property (nonatomic, retain)	NSNumber	*showSlideshowInHorizontal;
@property (nonatomic, retain)	NSNumber	*enableAudioInHorizontal;
@property (nonatomic, retain)	NSNumber	*showContentInHorizontal;
@property (nonatomic, retain)	NSNumber	*searchIndex;
@property (nonatomic, retain)	NSNumber	*defaultFontSize;
@property (nonatomic, retain)	NSNumber	*defaultInitDone;
@property (nonatomic, retain)   NSNumber    *enableCloud;
@property (nonatomic, readonly)   NSNumber    *askCloudQuestion;
@property (nonatomic, retain)	NSString	*searchString;
@property (nonatomic)			BOOL		levelRestored;
@property (nonatomic, retain)   NSNumber    *isPrivate;
@property (nonatomic, retain)   KeychainItemWrapper       *passwordItem;

@property (nonatomic, retain)   NSString    *UUID;
@property (nonatomic, retain)   NSNumber    *dbReadyForCloud;

@property (nonatomic) NSInteger	firstLevel;
@property (nonatomic) NSInteger	secondLevel;
@property (nonatomic) NSInteger	thirdLevel;

+ (GeoDefaults*)sharedGeoDefaultsInstance;
+ (NSString*)GetUUID;

- (void)saveFontSize;
- (void)initDefaultSettings;
- (void)saveDefaultSettings;
- (void)saveMapSettins;
- (void)saveSerarchSettings;
- (void)saveImageSlideshowSettings;
- (void)saveHorizontalSlideshowSettings;
- (BOOL)needRefreshCategory:(NSString*)category;
- (NSString*)getUniqueFilenameWithExt:(NSString*)ext;
- (NSString*)getAbsoluteDocPath:(NSString*)lastComponent;
- (NSInteger)getPasscode;
- (void)setPasscode:(NSInteger)passcode;
- (NSString*)getAbsoluteDocPathWithUUID:(NSString*)lastComponent;
- (void)dbInitDone;
- (void)dbCloudReady;
- (NSString*)getUniqueSupportFilenameWithExt:(NSString*)ext;

@end
