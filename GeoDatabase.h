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

@interface GeoCloudDocument : UIManagedDocument {

   // NSManagedObjectModel    *managedObjectModel;
    
}

//@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;

//- (id)contentsForType:(NSString *)typeName error:(NSError **)outError;
//- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError;
@end

@interface GeoDatabase : NSObject {
	// For management
	NSPersistentStoreCoordinator	*persistentStoreCoordinator__;
    NSManagedObjectModel			*managedObjectModel__;
    NSManagedObjectContext			*managedObjectContext__;
    NSMetadataQuery                 *ubiquitousQuery__;
    UIManagedDocument               *managedDocument;
	
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
    NSMetadataQuery                 *metaQuery;
}

@property (nonatomic, retain, readonly)	NSManagedObjectModel			*managedObjectModel;
@property (nonatomic, retain)           NSManagedObjectContext			*managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator	*persistentStoreCoordinator;
@property (nonatomic, retain)           NSMetadataQuery                 *ubiquitousQuery;
@property (nonatomic, retain, readonly) UIManagedDocument               *managedDocument;

@property (nonatomic, retain, readonly) NSMutableArray	*mailRecipientArray;
@property (nonatomic, readonly) MailRecipients			*mailRecipient;
@property (nonatomic, readonly) NSString				*defaultRecipient;

@property (nonatomic, retain, readonly) NSMutableArray	*categoryArray;
@property (nonatomic, readonly) GCategory				*categoryEntity;
@property (nonatomic, readonly) DefaultCategory			*defaultCategoryEntity;
@property (nonatomic, readonly) Journal					*journalEntity;
@property (nonatomic, retain)	NSMutableDictionary		*journalDict;
@property (nonatomic, retain)   NSMetadataQuery         *metaQuery;

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
- (void)setupCloud;
- (void)queryDidFinishGathering:(NSNotification *)notification;

- (void)mergeChangesFrom_iCloud:(NSNotification *)notification;
- (void)workaround_weakpackages_9653904:(NSDictionary*)options;
- (void)pollnewfiles_weakpackages:(NSNotification*)note;
- (NSManagedObjectContext*)managedObjectContextInstance;
- (void)upgradeDBForCloudReady;

@end
