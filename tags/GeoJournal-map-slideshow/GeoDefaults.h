//
//  GeoDefaults.h
//  GeoJournal
//
//  Created by Jae Han on 7/9/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

#define	NO_ACTIVE_CATEGORY	@"None"

@interface GeoDefaults : NSObject {
	NSNumber				*numberOfFileGenerated;
	NSString				*activeCategory;
	NSString				*geoDocumentPath;
	NSString				*applicationDocumentsDirectory;
	NSNumber				*testJournalCreated;
	NSNumber				*mapType;
	NSNumber				*categoryType;
	NSNumber				*numLocation;
	NSNumber				*mapSlideShowInterval;
	NSFileManager			*fileManager;
}

@property (nonatomic, retain)	NSNumber	*numberOfFileGenerated;
@property (nonatomic, retain)	NSString	*activeCategory;
@property (nonatomic, retain)	NSString	*applicationDocumentsDirectory;
@property (nonatomic, retain)	NSString	*geoDocumentPath;
@property (nonatomic, retain)	NSNumber	*testJournalCreated;
@property (nonatomic, retain)	NSNumber	*mapType;
@property (nonatomic, retain)	NSNumber	*categoryType;
@property (nonatomic, retain)	NSNumber	*numLocation;
@property (nonatomic, retain)	NSNumber	*mapSlideShowInterval;

+ (GeoDefaults*)sharedGeoDefaultsInstance;

- (void)initDefaultSettings;
- (void)saveDefaultSettings;
- (void)saveMapSettins;
- (NSString*)getUniqueFilenameWithExt:(NSString*)ext;
- (NSString*)getAbsoluteDocPath:(NSString*)lastComponent;

@end
