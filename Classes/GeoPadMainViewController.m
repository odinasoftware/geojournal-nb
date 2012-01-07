//
//  GeoPadMainViewController.m
//  GeoJournal
//
//  Created by Jae Han on 11/19/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "GeoJournalHeaders.h"
#import "GeoPadMainViewController.h"
#import "GeoPadTableViewController.h"
#import "GeoPopOverController.h"
#import "NoteViewController.h"
#import "ShowDisplayOptionController.h"
#import "PadMapViewController.h"

@implementation GeoPadMainViewController

@synthesize navBar;
@synthesize displayOptionPopOver;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (void)addButtons
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Category" style:UIBarButtonItemStyleBordered target:self action:@selector(showCategoryOptions:)];
    self.navigationItem.leftBarButtonItem = item;
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithTitle:@"SHOW" style:UIBarButtonItemStyleBordered target:self action:@selector(displayShowOptions:)];
    self.navigationItem.rightBarButtonItem = item;
    [item release];
    
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    TRACE("%s, top: %s\n", __func__, [NSStringFromClass([self.topViewController class]) UTF8String]);
    //Class = [self.topViewController class];
    
    //[self addButtons];
    if (self.topViewController == nil) {
		GeoPadTableViewController *aViewController = [[GeoPadTableViewController alloc] initWithNibName:@"GeoPadTableViewController" bundle:nil];
        
		[self pushViewController:aViewController animated:YES];
		[aViewController release];
	}
    self.navigationBarHidden = YES;
    /*
    UIImage *listImage = [UIImage imageNamed:@"list.png"];
    CGFloat width = self.view.frame.size.width;
    
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(width-80,5,70,26)];
    
    button.tintColor = [UIColor blueColor];
    //[button setTitle:@"Category" forState:UIControlStateNormal];
    [button setImage:listImage forState:UIControlStateNormal];
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [button addTarget:self action:@selector(displayShowOptions:) forControlEvents:UIControlEventTouchDown];
    [navBar addSubview:button];
    //[button release];
       
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(19,5,70,26)];
    
    button.tintColor = [UIColor blueColor];
    //[button setTitle:@"Category" forState:UIControlStateNormal];
    [button setImage:listImage forState:UIControlStateNormal];
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [button addTarget:self action:@selector(showCategoryOptions:) forControlEvents:UIControlEventTouchDown];
    [navBar addSubview:button];
    //[button release];
    */
    /*
    UIButton *item = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [item setFrame:CGRectMake(0, 0, 50, 30)];
    [item setTitle:@"test" forState:UIControlStateNormal];
    [navBar addSubview:item];
     */
    
    //TTButton *b = [TTButton buttonWithStyle:@"toolbarButton:" title:@"Toolbar Button"];
    //[navBar addSubview:b];
    
    
}

- (void)showCategoryOptions:(id)sender
{
    TRACE_HERE;
	
    GeoPopOverController *controller = [[GeoPopOverController alloc] initWithNibName:@"GeoPopOverController" bundle:nil];
    //NoteViewController *controller = [[NoteViewController alloc] initWithNibName:@"NoteView" bundle:nil];
    // TODO: set proper delegate; should be GeoPadTableViewController
    TRACE("%s, view controller: %s\n", __func__, class_getName([self.topViewController class]));
    controller.delegate = (id) self.topViewController;
    UIPopoverController *aPopover = [[UIPopoverController alloc] initWithContentViewController:controller];
    [controller release];
    
    //DEBUG_RECT("Category option:", [sender frame]);
    //[aPopover presentPopoverFromRect:[sender frame] inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [aPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)displayShowOptions:(id)sender
{
    ShowDisplayOptionController *controller = [[ShowDisplayOptionController alloc] initWithNibName:@"ShowDisplayOptionController" bundle:nil];
    //NoteViewController *controller = [[NoteViewController alloc] initWithNibName:@"NoteView" bundle:nil];
    controller.bypassDelegate = self;
    UIPopoverController *aPopover = [[UIPopoverController alloc] initWithContentViewController:controller];
    [controller release];
    
    //DEBUG_RECT("Show option:", [sender frame]);
    
    self.displayOptionPopOver = aPopover;
    //[aPopover presentPopoverFromRect:CGRectMake(100, 10, 70, 26) inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [aPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [aPopover release];
}

#pragma ChangeDisplayViewDelegate
- (void)dissmissDisplayViewPopover:(id)sender
{
    [self.displayOptionPopOver dismissPopoverAnimated:YES];
}

- (void)changeDisplayView:(NSInteger)viewIndex
{
    TRACE("%s, index: %d, %s\n", __func__, viewIndex, [NSStringFromClass([self.topViewController class]) UTF8String]);
    
    for (UIViewController *v in self.viewControllers) {
        TRACE("v: %s\n", [NSStringFromClass([v class]) UTF8String]);
    }
    switch (viewIndex) {
        case 0:
            if (![self.topViewController isKindOfClass:[GeoPadTableViewController class]]) {
                // Show NoteViewController
                GeoPadTableViewController *aViewController = [[GeoPadTableViewController alloc] initWithNibName:@"GeoPadTableViewController" bundle:nil];
                [self setViewControllers:[NSArray arrayWithObjects:aViewController, nil] animated:NO];
            }
            break;
        case 1:
            if (![self.topViewController isKindOfClass:[PadMapViewController class]]) {
                //[self addButtons];
                //[self popViewControllerAnimated:NO];
                PadMapViewController *aViewController = [[PadMapViewController alloc] initWithNibName:@"PadMapViewController" bundle:nil];
                [self setViewControllers:[NSArray arrayWithObjects:aViewController, nil] animated:NO];
                //[self pushViewController:aViewController animated:YES];
                //[aViewController release];
            }
            break;
        case 2:
            break;
        default:
            break;
    }
}
#pragma -

@end
