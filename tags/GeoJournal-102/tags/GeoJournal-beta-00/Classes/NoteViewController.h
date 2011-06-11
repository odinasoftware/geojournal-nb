//
//  NoteViewController.h
//  GeoJournal
//
//  Created by Jae Han on 5/23/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>
#import <CoreData/CoreData.h>

@class AddCategory;
@class Category;
@class GeoTakeController;
@class JournalViewController;
@class ButtonScrollView;
@class NoteTableView;

@interface NoteViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UIAlertViewDelegate> {
	@private
	IBOutlet	UIPickerView			*secionPicker;
	IBOutlet	UITableView				*theTableView;
	IBOutlet	UIButton				*journalButton;
	IBOutlet	UIView					*layout;
	IBOutlet	ButtonScrollView		*buttonFrame;
	IBOutlet	UILabel					*currentCategoryLabel;
	
	//CFURLRef		soundFileURLRef;
	//SystemSoundID	soundFileObject;
	NSArray							*defaultCategory;
	NSMutableArray					*buttons;
	UIImage							*selectionImage;
	UIImage							*infoButtonImage;
	UIColor							*selectedColor;
	AddCategory						*addCategoryController;
	NSMutableArray					*categoryArray;
	NSInteger						selectedButton;
	Category						*selectedCategory;
	GeoTakeController				*journalController;
	
	@private
	JournalViewController			*_journalController;
	AddCategory						*_addController;
	NSIndexPath						*_deleteIndex;
}

//@property (readwrite)	CFURLRef		soundFileURLRef;
//@property (readonly)	SystemSoundID	soundFileObject;
@property (nonatomic, readonly)		NSInteger				numberOfCategory;
@property (nonatomic, retain)		AddCategory				*addCategoryController;
@property (nonatomic, retain)		NSMutableArray			*categoryArray;
@property (nonatomic, retain)		Category				*selectedCategory;
@property (nonatomic, retain)		GeoTakeController		*journalController;
@property (nonatomic, retain)		NSArray					*defaultCategory;
@property (nonatomic, retain)		ButtonScrollView		*buttonFrame;
@property (nonatomic, retain)		UITableView				*theTableView;
@property (nonatomic, retain)		UIColor					*selectedColor;
@property (nonatomic, retain)		UIImage					*infoButtonImage;
@property (nonatomic, retain)		UIImage					*selectionImage;
@property (nonatomic, retain)		UILabel				 	*currentCategoryLabel;
@property (nonatomic, retain)		JournalViewController	*_journalController;
@property (nonatomic, retain)		AddCategory				*_addController;
@property (nonatomic, retain)		NSIndexPath				*_deleteIndex;

- (void)openTakeJournal:(id)sender;
- (void)addCategory;
- (void)editCategory;
- (void)initCategoryButtons;
- (void)selectCategory;
- (void)dragToLeft;
- (void)dragToRight;
- (void)saveCategory;
- (void)doneEditing;
- (void)cancelEditing;
- (void)setNormalButtons;
- (void)setScrollViewSize;
- (void)showSelectedButton;
- (void)verifyDefaultCategories;
- (void)loadFromDatabase;
- (void)restoreLevel;
- (void)selectButton:(NSSet*)touches;
- (void)deleteFromCategory:(NSInteger)index;
- (Category*)getCategory:(NSString*)name withIndex:(NSInteger)i;
- (UIButton*)getScrollableButton:(NSString*)title;
- (void)addNewScrollableButton:(NSString*)title;
- (void)removeFromScrollableButtons:(NSInteger)index;
- (void)scrollToButton:(NSInteger)index;
- (void)selectButtonWithIndex:(NSInteger)index;
- (void)showSelectedCategory:(NSString*)text;

@end
