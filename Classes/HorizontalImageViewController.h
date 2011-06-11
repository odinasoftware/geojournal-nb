//
//  FirstViewController.h
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Journal;

@interface HorizontalImageViewController : UIViewController {
	IBOutlet UIView				*_imageView;
	IBOutlet UIImageView		*articleImageView;
	IBOutlet UIImageView		*background;
	
	//IBOutlet UISlider			*_slider;
	
	Journal						*_journal;
	BOOL						sliderBeingUsed;
	BOOL						sliderHidden;
	CGRect						imageViewRect;
}

@property (nonatomic, retain) UIImageView			*background;
@property (nonatomic, retain) UIView				*_imageView;
@property (nonatomic, retain) Journal				*_journal;
@property (nonatomic, retain) UIImageView			*articleImageView;
@property (nonatomic) BOOL							sliderBeingUsed;
@property (nonatomic) BOOL							sliderHidden;

- (IBAction)sliderValueChanged:(id)sender;
- (IBAction)sliderTouchEnd:(id)sender;

- (id)initWithNibName:(NSString *)nibNameOrNil withJournal:(Journal*)journal;

- (void)reDrawWithJournal:(Journal*)j;
//- (void)showSliderSetting;
//- (void)hideSliderSetting;
- (void)hideContent;

@end
