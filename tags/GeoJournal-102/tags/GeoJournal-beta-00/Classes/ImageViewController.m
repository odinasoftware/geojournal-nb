//
//  FirstViewController.m
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//
#import "ImageViewController.h"
#import "GeoDefaults.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"

#define MIN_SLIDER_VALUE			1.0
#define MAX_SLIDER_VALUE			10.0
#define IMAGE_VIEW_HEIGHT			460.0


@implementation ImageViewController

@synthesize _slider;
@synthesize _imageView;
@synthesize _sliderView;
@synthesize _journal;
@synthesize articleImageView;
@synthesize articleTitle;
@synthesize articleDescription;
@synthesize sliderBeingUsed;
@synthesize sliderHidden;

- (id)initWithNibName:(NSString *)nibNameOrNil withJournal:(Journal*)journal {
	if (self = [super initWithNibName:nibNameOrNil bundle:nil]) {
		// Initialization code
		self._journal = journal;
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
 - (void)loadView {
 }
 */

- (void)viewDidLoad 
{
	UIImage *image = nil;
	
	imageViewRect = articleImageView.frame;
	
	if (self._journal != nil) {
		if (self._journal.picture == nil) {
			articleImageView.frame = imageViewRect;
			articleImageView.image = [UIImage imageNamed:@"no-picture.png"];
		}
		else {
			NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self._journal.picture];
			image = [[UIImage alloc] initWithContentsOfFile:pictureLink];
			articleImageView.image = image;
		}
		
		float x, y, move_x, move_y;
		GET_COORD_IN_PROPORTION(imageViewRect.size, articleImageView.image, &x, &y);
		move_x = MAKE_CENTER(x - imageViewRect.size.width);
		move_y = MAKE_CENTER(y - imageViewRect.size.height);
		TRACE("%s, image: w: %f, h: %f\n", __func__, articleImageView.image.size.width, articleImageView.image.size.height);
		TRACE("%s, move_x: %f, move_y: %f x: %f, y: %f\n", __func__, move_x, move_y, x, y);
		
		articleImageView.frame = CGRectMake(imageViewRect.origin.x+move_x, imageViewRect.origin.y+move_y, x, y);
	
		articleDescription.text = self._journal.text;
		articleDescription.font = [UIFont systemFontOfSize:15.0];
		articleDescription.textColor = [UIColor whiteColor]; 
		articleTitle.text = self._journal.title;
		[image release];
		
		self._slider.minimumValue = MIN_SLIDER_VALUE;
		self._slider.maximumValue = MAX_SLIDER_VALUE;
		int v = [[GeoDefaults sharedGeoDefaultsInstance].imageSlideShowInterval intValue];
		self._slider.value = v;
		
	}
	else {
		// no journal case
		[self showNoPictureWarning];
	}
	
	[self.view addSubview:self._imageView];
	TRACE("%s, %s\n", __func__, [articleTitle.text UTF8String]);
}

- (void)showNoPictureWarning
{
	articleDescription.text = @"No picture found in this categoy. Please select different category or select entire category to view pictures";
	articleDescription.font = [UIFont systemFontOfSize:15.0];
	articleDescription.textColor = [UIColor whiteColor]; 
	articleTitle.text = @"No picture found in this category.";
	articleImageView.frame = imageViewRect;
	articleImageView.image = [UIImage imageNamed:@"no-picture.png"];
		
}

/* Problem when the view is unloaded.
 *   When this view is unloaded, redrawing this way will end up failing because of nil pointer.
 */
- (void)reDrawWithJournal:(Journal*)j 
{
	UIImage *image = nil;
	self._journal = j;
	
	if (j != nil) {
		if (self._journal.picture == nil) {
			articleImageView.frame = imageViewRect;
			articleImageView.image = [UIImage imageNamed:@"no-picture.png"];
		}
		else {
			
			NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self._journal.picture];
			image = [[UIImage alloc] initWithContentsOfFile:pictureLink];
		
			articleImageView.image = image;
		}
		float x, y, move_x, move_y;
		GET_COORD_IN_PROPORTION(imageViewRect.size, articleImageView.image, &x, &y);
		move_x = MAKE_CENTER(x - imageViewRect.size.width);
		move_y = MAKE_CENTER(y - imageViewRect.size.height);
		TRACE("%s, image: w: %f, h: %f\n", __func__, articleImageView.image.size.width, articleImageView.image.size.height);
		TRACE("%s, move_x: %f, move_y: %f x: %f, y: %f\n", __func__, move_x, move_y, x, y);
		
		articleImageView.frame = CGRectMake(imageViewRect.origin.x+move_x, imageViewRect.origin.y+move_y, x, y);
		articleDescription.text = self._journal.text;
		//articleDescription.font = [UIFont systemFontOfSize:15.0];
		//articleDescription.textColor = [UIColor whiteColor]; 
		articleTitle.text = self._journal.title;
		[image release];
	}
	else {
		[self showNoPictureWarning];
	}
	
}

- (IBAction)sliderValueChanged:(id)sender
{
	TRACE_HERE;
	sliderBeingUsed = YES;
}

- (IBAction)sliderTouchEnd:(id)sender
{
	TRACE_HERE;
	sliderBeingUsed = NO;
}

- (void)hideSliderSetting
{
	sliderHidden = YES;
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.5];
	
	CGRect rect = [self._sliderView frame];
	rect.origin.y = 380.0; //-80.0f - rect.size.height;
	[self._sliderView setFrame:rect];
	
	// Complete the animation
	[UIView commitAnimations];		
	[GeoDefaults sharedGeoDefaultsInstance].imageSlideShowInterval = [NSNumber numberWithInt:self._slider.value];
	[[GeoDefaults sharedGeoDefaultsInstance] saveImageSlideshowSettings];
}

- (void)showSliderSetting
{
	sliderBeingUsed = NO;
	sliderHidden = NO;
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	float originY = IMAGE_VIEW_HEIGHT-self._sliderView.frame.size.height-90.0;
	self._sliderView.frame = CGRectMake(0.0, originY,
										  self._sliderView.frame.size.width, self._sliderView.frame.size.height);
	TRACE("%s, x: %f, y: %f, w: %f, h: %f\n", __func__, self._sliderView.frame.origin.x, 
		  self._sliderView.frame.origin.y,
		  self._sliderView.frame.size.width,
		  self._sliderView.frame.size.height);
	//self._sliderView 
	[self.view addSubview:self._sliderView];
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.5];
	
	CGRect rect = [self._sliderView frame];
	rect.origin.y = originY; //380.0f;
	[self._sliderView setFrame:rect];
	[UIView commitAnimations];
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	NSLog(@"%s", __func__);
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)viewDidUnload
{
	TRACE_HERE;
	//self.articleImageView.image = nil;
	
	self.articleImageView = nil;
	self.articleDescription = nil;
	self.articleTitle = nil;
	self._imageView = nil;
	self._sliderView = nil;
	self._slider = nil;
	 
}

- (void)dealloc {
	TRACE_HERE;
	//TRACE("%s, %d\n", __func__, [articleImageView.image retainCount]);
	[_slider release];
	[_imageView release];
	[_sliderView release];
	[_journal release];
	[articleImageView release];
	[articleDescription release];
	[articleTitle release];
	
	[super dealloc];
}

@end
