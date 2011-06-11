//
//  SlideShowViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/20/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageViewController;
@class Journal;
@class ArticleScrollView;
@class JournalEntryViewController;

@interface PageViewControllerPointer : NSObject
{
	ImageViewController *controller;
	NSInteger			page;
}

@property (nonatomic, assign) NSInteger page;
@property (nonatomic, retain) ImageViewController *controller;

- (id)initWithPage:(NSInteger)num;

@end

@interface SlideShowViewController : UIViewController <UIScrollViewDelegate> {

	IBOutlet ArticleScrollView	*_scrollView;
	
	NSMutableArray				*categoryArray;
	NSArray						*journalArray;
	NSArray						*controllerArray;
	NSInteger					currentArrayPointer;
	NSInteger					currentPage;
	NSInteger					currentSlideshowPage;
	NSInteger					currentSelectedPage;
	NSInteger					numberOfPages;
	BOOL						isSlideShowRunning;
	NSTimer						*slideShowTimer;
	ImageViewController			*currentSlideImageController;
	
	@private	
	NSString					*_category;
	JournalEntryViewController	*_journalView;
	UILabel						*_titleLabel;
}

@property (nonatomic, retain) NSString						*_category;
@property (nonatomic, retain) ArticleScrollView				*_scrollView;
@property (nonatomic, retain) NSMutableArray				*categoryArray;
@property (nonatomic, retain) NSArray						*journalArray;
@property (nonatomic, retain) NSTimer						*slideShowTimer;
@property (nonatomic, retain) ImageViewController			*currentSlideImageController;
@property (nonatomic, retain) NSArray						*controllerArray;
@property (nonatomic, retain) JournalEntryViewController	*_journalView;
@property (nonatomic, retain) UILabel						*_titleLabel;

- (void)resetView;
- (void)restoreLevel;
- (void)refreshView;
- (Journal*)getJournalForPage:(NSInteger)page;
- (void)loadImageView:(NSInteger)page;
- (void)playSlideShow:(id)sender;
- (void)stopSlideShow:(id)sender;
- (void)showNextImage:(NSTimer*)timer;
- (void)showImageControls:(int)tapCount;
- (CGRect)getRectFromPage:(int)page;
- (ImageViewController*)getImageControllerWithPage:(NSInteger)page;
- (ImageViewController*)getNextImageViewControllerWithPage:(NSInteger)page needRedraw:(BOOL*)redraw;

@end
