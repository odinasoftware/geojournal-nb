//
//  FirstViewController.m
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//
#import "HorizontalImageViewController.h"
#import "GeoDefaults.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"

#define MIN_SLIDER_VALUE			1.0
#define MAX_SLIDER_VALUE			10.0
#define IMAGE_VIEW_HEIGHT			460.0
#define BACKGROUND_X				20.0
#define BACKGROUND_Y				20.0
#define BACKGROUND_WIDTH			40.0
#define BACKGROUND_HEIGHT			35.0


@implementation HorizontalImageViewController

@synthesize background;
@synthesize _imageView;
@synthesize _journal;
@synthesize articleImageView;
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
	NSData *data = nil;
	
	imageViewRect = articleImageView.frame;

	if (self._journal != nil) {
		if (self._journal.picture == nil) {
			articleImageView.frame = imageViewRect;
			articleImageView.image = [UIImage imageNamed:@"no-picture.png"];
		}
		else {
			NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self._journal.picture];
			data = [[NSData alloc] initWithContentsOfFile:pictureLink];
			image = [[UIImage alloc] initWithData:data];
			articleImageView.image = image;
		}
		
		float x, y, move_x, move_y;
		GET_COORD_IN_PROPORTION(imageViewRect.size, articleImageView.image, &x, &y);
		move_x = MAKE_CENTER(x - imageViewRect.size.width);
		move_y = MAKE_CENTER(y - imageViewRect.size.height);
		
		//float move = (articleImageView.frame.size.width > x ? (articleImageView.frame.size.width - x)/2.0:0.0);
		background.frame = CGRectMake(imageViewRect.origin.x+move_x-BACKGROUND_X, imageViewRect.origin.y+move_y-BACKGROUND_Y, x+BACKGROUND_WIDTH, y+BACKGROUND_HEIGHT);
		articleImageView.frame = CGRectMake(imageViewRect.origin.x+move_x, imageViewRect.origin.y+move_y, x, y);
		
		DEBUG_RECT("Horizontal", articleImageView.frame);
		[image release];
		[data release];
		
		//self._slider.minimumValue = MIN_SLIDER_VALUE;
		//self._slider.maximumValue = MAX_SLIDER_VALUE;
		//int v = [[GeoDefaults sharedGeoDefaultsInstance].imageSlideShowInterval intValue];
		//self._slider.value = v;
		[self.view addSubview:self._imageView];
		//TRACE("%s, %s\n", __func__, [articleTitle.text UTF8String]);
	}
}

- (void)reDrawWithJournal:(Journal*)j 
{
	UIImage *image = nil;
	NSData *data = nil;

	self._journal = j;
	if (j != nil) {
		if (self._journal.picture == nil) {
			articleImageView.frame = imageViewRect;
			articleImageView.image = [UIImage imageNamed:@"no-picture.png"];
		}
		else {
			NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self._journal.picture];
			data = [[NSData alloc] initWithContentsOfFile:pictureLink];
			image = [[UIImage alloc] initWithData:data];
			articleImageView.image = image;
		}
		
		float x, y, move_x, move_y;
		GET_COORD_IN_PROPORTION(imageViewRect.size, articleImageView.image, &x, &y);
		move_x = MAKE_CENTER(x - imageViewRect.size.width);
		move_y = MAKE_CENTER(y - imageViewRect.size.height);
		
		//float move = (articleImageView.frame.size.width > x ? (articleImageView.frame.size.width - x)/2.0:0.0);
		background.frame = CGRectMake(imageViewRect.origin.x+move_x-BACKGROUND_X, imageViewRect.origin.y+move_y-BACKGROUND_Y, x+BACKGROUND_WIDTH, y+BACKGROUND_HEIGHT);
		articleImageView.frame = CGRectMake(imageViewRect.origin.x+move_x, imageViewRect.origin.y+move_y, x, y);
		
		
		[image release];
		[data release];
	}
	else {
		articleImageView.image = [UIImage imageNamed:@"no-picture-horizontal.png"];
	}
	
}

- (void)hideContent
{
	//self._sliderView.hidden = YES;
	//[self._sliderView removeFromSuperview];
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

/*

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
	//[GeoDefaults sharedGeoDefaultsInstance].imageSlideShowInterval = [NSNumber numberWithInt:self._slider.value];
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
*/


- (void)didReceiveMemoryWarning {
	NSLog(@"%s", __func__);
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
	[self viewDidUnload];
}

- (void)viewDidUnload
{
	TRACE_HERE;
	/*
	self.articleImageView = nil;
	self._imageView = nil;
	self.background = nil;
	 */
}

- (void)dealloc {
	//TRACE("%s, %d\n", __func__, [articleImageView.image retainCount]);
	[background release];
	[_imageView release];
	[_journal release];
	[articleImageView release];
	
	[super dealloc];
}

@end
