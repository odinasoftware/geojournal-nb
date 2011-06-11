//
//  FirstViewController.h
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Journal;

@interface ImageViewController : UIViewController {
	IBOutlet UIView				*_imageView;
	IBOutlet UIView				*_sliderView;
	IBOutlet UIImageView		*articleImageView;
	IBOutlet UILabel			*articleDescription;
	IBOutlet UILabel			*articleTitle;
	IBOutlet UISlider			*_slider;
	
	Journal						*_journal;
	BOOL						sliderBeingUsed;
	BOOL						sliderHidden;
	CGRect						imageViewRect;
}

@property (nonatomic, retain) UISlider				*_slider;
@property (nonatomic, retain) UIView				*_imageView;
@property (nonatomic, retain) UIView				*_sliderView;
@property (nonatomic, retain) Journal				*_journal;
@property (nonatomic, retain) UIImageView			*articleImageView;
@property (nonatomic, retain) UILabel				*articleDescription;
@property (nonatomic, retain) UILabel				*articleTitle;
@property (nonatomic) BOOL							sliderBeingUsed;
@property (nonatomic) BOOL							sliderHidden;

- (IBAction)sliderValueChanged:(id)sender;
- (IBAction)sliderTouchEnd:(id)sender;

- (id)initWithNibName:(NSString *)nibNameOrNil withJournal:(Journal*)journal;

- (void)reDrawWithJournal:(Journal*)j;
- (void)showSliderSetting;
- (void)hideSliderSetting;
- (void)showNoPictureWarning;

@end
