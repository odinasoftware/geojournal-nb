//
//  JournalViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/10/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>

#ifdef BANNER_AD
#import "QWAdView.h"
#endif

@class Category;
@class GeoTakeController;
@class JournalEntryViewController;
@class ButtonScrollView;
@class NoteViewController;

@interface DateIndex : NSObject
{
	NSString	*dateString;
	NSInteger	index;
}

@property (nonatomic, retain) NSString		*dateString;
@property (nonatomic) NSInteger				index;

@end

#ifdef BANNER_AD
@interface JournalViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, QWAdViewDelegate> {
#else
@interface JournalViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {
#endif
	IBOutlet UITableView			*tableView;
	IBOutlet ButtonScrollView		*buttonFrame;
	IBOutlet UIView					*categoryEditView;
	IBOutlet UILabel				*categoryLabel;
	IBOutlet UIImageView			*leftArrow;
	IBOutlet UIImageView			*rightArrow;
	
	NSArray							*defaultCategory;
	NSArray							*journalArray;
	UIImage							*defaultImage;
	BOOL							needToReload;
	BOOL							isCategoryChanged;
	
	NSMutableArray					*buttons;
	UIImage							*selectionImage;
	UIImage							*infoButtonImage;
	UIImage							*listImage;
	UIColor							*selectedColor;
	NSMutableArray					*categoryArray;
	NSInteger						selectedButton;
	Category						*selectedCategory;

	@private
	UIImage							*picasaIcon;
	UIImage							*uploadNotSelectedIcon;
	UIImage							*uploadSelectedIcon;
	UIImage							*backgroundLabel;
	UIImage							*backgroundLabel2;
	NSMutableArray					*_dateArray;
	JournalEntryViewController		*_journalView;
	GeoTakeController				*journalController;
	NoteViewController				*editCategoryController;
	BOOL							picasaSyncing;
	//CFURLRef						soundFileURLRef;
	//SystemSoundID					soundFileObject;
#ifdef BANNER_AD
	QWAdView						*_bannerAd;
#endif
}

@property (nonatomic, readonly)		NSInteger				numberOfCategory;
@property (nonatomic, retain)	UIImageView					*rightArrow;
@property (nonatomic, retain)	UIImageView					*leftArrow;
@property (nonatomic, retain)	UILabel						*categoryLabel;
@property (nonatomic, retain)	UIImage						*uploadSelectedIcon;
@property (nonatomic, retain)	UIImage						*uploadNotSelectedIcon;
@property (nonatomic, retain)	UIImage						*picasaIcon;
@property (nonatomic, retain)	UIImage						*backgroundLabel;
@property (nonatomic, retain)	UIImage						*backgroundLabel2;
@property (nonatomic, retain)	UIView						*categoryEditView;
@property (nonatomic, retain)	NoteViewController			*editCategoryController;
@property (nonatomic, retain)	Category					*selectedCategory;
@property (nonatomic, retain)	NSMutableArray				*categoryArray;
@property (nonatomic, retain)	ButtonScrollView			*buttonFrame;
@property (nonatomic, retain)	UIImage						*infoButtonImage;
@property (nonatomic, retain)	UIImage						*selectionImage;
@property (nonatomic, retain)	UIImage						*listImage;
@property (nonatomic, retain)	NSMutableArray				*buttons;
@property (nonatomic, retain)	UIColor						*selectedColor;
@property (nonatomic, retain)	NSArray						*defaultCategory;
@property (nonatomic, retain)	UITableView					*tableView;
@property (nonatomic, retain)	UIImage						*defaultImage;
@property (nonatomic, retain)	NSArray						*journalArray;
@property (nonatomic, retain)	NSMutableArray				*_dateArray;
@property (nonatomic, retain)	GeoTakeController			*journalController;
@property (nonatomic, retain)	JournalEntryViewController	*_journalView;

#ifdef BANNER_AD
@property (retain) QWAdView	*bannerAd;
#endif


@property (nonatomic)			BOOL			isCategoryChanged;

- (void)restoreLevel;
- (void)reloadJournalArray;
- (void)saveJournalToDatabase;
- (void)setReload:(BOOL)reload;
- (void)fetchJournalForCategory:(Category*)category;

- (Category*)getCategory:(NSString*)name withIndex:(NSInteger)i;
- (Category*)getCategory:(NSString*)name;
- (UIButton*)getScrollableButton:(NSString*)title;

- (void)picasaSync;
- (void)loadFromDatabase;
- (void)setNormalButtons;
- (void)initCategoryButtons;
- (void)showSelectedButton;
- (void)setScrollViewSize;
- (void)segmentAction:(id)sender;

- (void)deSelectButton:(NSInteger)index;
- (void)selectButton:(NSSet*)touches;
- (void)editCategory:(id)sender;
- (void)categorySettingDone:(id)sender;
- (void)editNoteCategory;
- (void)setEditNoteButtons;
- (void)scrollToButton:(NSInteger)index;
- (void)removeFromScrollableButtons:(NSInteger)index;
- (void)selectButtonWithIndex:(NSInteger)index;
- (void)addNewScrollableButton:(NSString*)title;


@end
