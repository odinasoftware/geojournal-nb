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

@interface NoteViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {
	@private
	IBOutlet	UIPickerView			*secionPicker;
	IBOutlet	UITableView				*theTableView;
	IBOutlet	UIButton				*journalButton;
	IBOutlet	UIView					*layout;
	IBOutlet	ButtonScrollView		*buttonFrame;
	IBOutlet	JournalViewController	*journalViewController;
	
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
}

//@property (readwrite)	CFURLRef		soundFileURLRef;
//@property (readonly)	SystemSoundID	soundFileObject;
@property (nonatomic, readonly)		NSInteger				numberOfCategory;
@property (nonatomic, retain)		AddCategory				*addCategoryController;
@property (nonatomic, retain)		NSMutableArray			*categoryArray;
@property (nonatomic, retain)		Category				*selectedCategory;
@property (nonatomic, retain)		GeoTakeController		*journalController;
@property (nonatomic, retain)		JournalViewController	*journalViewController;
@property (nonatomic, retain)		NSArray					*defaultCategory;
@property (nonatomic, retain)		ButtonScrollView		*buttonFrame;
@property (nonatomic, retain)		UITableView				*theTableView;

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
- (void)deleteFromCategory:(NSInteger)index;
- (UIButton*)getScrollableButton:(NSString*)title;

@end
