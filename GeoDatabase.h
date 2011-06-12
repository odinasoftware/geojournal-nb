//
//  GeoDatabase.h
//  GeoJournal
//
//  Created by Jae Han on 7/8/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MailRecipients;
@class GCategory;
@class DefaultCategory;
@class Journal;
@class PictureFrame;
@class Pictures;

@interface GeoDatabase : NSObject {
	// For management
	NSPersistentStoreCoordinator	*persistentStoreCoordinator;
    NSManagedObjectModel			*managedObjectModel;
    NSManagedObjectContext			*managedObjectContext;	    
	
	// MAIL Database entities
	NSMutableArray					*mailRecipientArray;
	MailRecipients					*mailRecipient;
	NSString						*defaultRecipient;
	
	// GCategory DB entities
	NSMutableArray					*categoryArray;
	GCategory						*categoryEntity;
	DefaultCategory					*defaultCategoryEntity;
	
	// to store journal entries
	NSMutableDictionary				*journalDict;
	
	// Journal entities
	Journal							*journalEntity;
}

@property (nonatomic, retain, readonly)	NSManagedObjectModel			*managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext			*managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator	*persistentStoreCoordinator;

@property (nonatomic, retain, readonly) NSMutableArray	*mailRecipientArray;
@property (nonatomic, readonly) MailRecipients			*mailRecipient;
@property (nonatomic, readonly) NSString				*defaultRecipient;

@property (nonatomic, retain, readonly) NSMutableArray	*categoryArray;
@property (nonatomic, readonly) GCategory				*categoryEntity;
@property (nonatomic, readonly) DefaultCategory			*defaultCategoryEntity;
@property (nonatomic, readonly) Journal					*journalEntity;
@property (nonatomic, retain)	NSMutableDictionary		*journalDict;

// Class definitions
+ (GeoDatabase*)sharedGeoDatabaseInstance;

// Methods
- (void)save;
- (void)deleteObject:(NSManagedObject*)object;
- (NSArray*)journalByCategory:(GCategory*)category;
- (void)deleteJournalObject:(Journal*)journal forCategory:(GCategory*)category;
- (NSMutableArray*)picturesForJournal:(NSString*)journalPicture;
- (PictureFrame*)pictureFrameEntity;
- (Pictures*)picturesEntity;
- (void)savePicture:(NSString*)picture toJournal:(Journal*)journal;
- (BOOL)removePicture:(NSString*)picture fromJournal:(Journal*)journal deleteFile:(BOOL)shouldDeleteFile;
- (void)removeJournalPicture:(Journal*)journal;
- (void)replacePicture:(NSString*)picture forJournal:(Journal*)journal;
- (PictureFrame*)getFrameForJournal:(Journal*)journal;

@end
