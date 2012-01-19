//
//  PadEntryViewController.m
//  GeoJournal
//
//  Created by Jae Han on 11/14/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "GeoPadHeaders.h"
#import "PadEntryViewController.h"
#import "GeoDefaults.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "GeoDatabase.h"
#import "GeoSession.h"
#import "JournalViewController.h"
#import "EditText.h"
#import "ImageArrayScrollController.h"
#import "FullImageViewController.h"
#import "StatusViewController.h"
#import "HorizontalViewController.h"

#define BOTTOM_MARGIN			80

extern NSString *getTitle(NSString *content);
extern NSString *getThumbnailFilename(NSString *filename);
extern NSString *getThumbnailOldFilename(NSString *filename);
extern void saveImageToFile(UIImage *image, NSString *filename);
extern UIImage *getReducedImage(UIImage *image, float ratio);
extern void *display_image_in_thread(void *arg);
extern NSString *getPrinterableDate(NSDate *date, NSInteger *day);

@implementation PadEntryViewController


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
            [self syncWithFacebook];
            break;
        case 2:
            if ([TWTweetComposeViewController class]) {
                [self syncWithTweet];
            }
            else {
                [self syncWithMail];
            }
            break;
        case 3:
            [self syncWithMail];
            break;
        case 0:
            break;
        default:
            break;
    }
}


#pragma mark -
- (void)chooseActions:(id)sender
{
    UIAlertView *alert = nil;
    
    if ([TWTweetComposeViewController class]) {
        alert = [[UIAlertView alloc] initWithTitle:@"Sync Article" 
                                           message:@""
                                          delegate:self 
                                 cancelButtonTitle:@"Cancel" 
                                 otherButtonTitles:@"Facebook", @"Tweet", @"Send mail", nil];
    }
    else {
        alert = [[UIAlertView alloc] initWithTitle:@"Sync Article" 
                                           message:@""
                                          delegate:self 
                                 cancelButtonTitle:@"Cancel" 
                                 otherButtonTitles:@"Facebook", @"Send mail", nil];
    }
	[alert show];
	[alert release];
    
}

- (void)viewDidLoad
{
    TRACE_HERE;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _sync_action = NO_DEFAULT_ACTION;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                                                                           target:self 
                                                                                           action:@selector(reloadArticles:)];
	//defaultTintColor = [segmentedControl.tintColor retain];	// keep track of this for later
	
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                          target:self 
                                                                          action:@selector(chooseActions:)];
	self.navigationItem.rightBarButtonItem = item;
    [item release];
	
	_frameRect = self.imageFrameView.frame;
	_imageRect = self.imageForJournal.frame;
	_containerViewRect = self.containerView.frame;
	_creationDateLabelRect = self.creationDateLabel.frame;
	_locationLabelRect = self.locationLabel.frame;
	_textForJournalRect = self.textForJournal.frame;
	_stretchButtonRect = self.stretchButton.frame;
    
	fontSize = [[GeoDefaults sharedGeoDefaultsInstance].defaultFontSize intValue];
	if (fontSize < DEFAULT_FONT_SIZE) {
		fontSize = DEFAULT_FONT_SIZE;
	}
    self.navigationController.navigationBarHidden = NO;
    //self.toolbar.userInteractionEnabled = YES;
    //UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:nil];
    //[self.toolbar setItems:self.toolbar.items];
    DEBUG_RECT("Scroll View:", self.scrollView.frame);
}



@end
