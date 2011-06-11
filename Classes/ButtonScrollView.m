//
//  ButtonScrollView.m
//  GeoJournal
//
//  Created by Jae Han on 7/13/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "ButtonScrollView.h"
#import "GeoJournalHeaders.h"
#import "JournalViewController.h"

@implementation ButtonScrollView

@synthesize noteDelegate;

- (void)viewDidLoad
{
	//self.delegate = self;
	if ([self canBecomeFirstResponder] == YES) {
		TRACE("%s, becomre the first responder.\n", __func__);
		[self becomeFirstResponder];
	}
	//self.exclusiveTouch = YES;
	//self.multipleTouchEnabled = YES;
	touchEvent = BUTTON_NONE;
}

#pragma mark SCROLL EVENT
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	TRACE("%s\n", __func__);
}

- (void)scrollViewDidScroll:(UIScrollView *)sender 
{
	TRACE_HERE;
}

#pragma mark TOUCHES EVENTS
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
	/*
	for (UITouch *t in touches) {
		CGPoint point = [t locationInView:self];
		TRACE("<x: %f,y: %f>", point.x, point.y);
	}
	 
	TRACE("\n");
	 */
	touchEvent = BUTTON_PRESSED;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
	touchEvent = BUTTON_NONE;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
	/*
	for (UITouch *t in touches) {
		CGPoint point = [t locationInView:self];
		TRACE("<x: %f,y: %f>", point.x, point.y);
	}
	TRACE("\n");
	 */
	if (BUTTON_PRESSED) {
		// User selected a button
		[self.noteDelegate selectButton:touches];
	}
	touchEvent = BUTTON_UP;
	
	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
	/*
	for (UITouch *t in touches) {
		CGPoint point = [t locationInView:self];
		TRACE("<x: %f,y: %f>", point.x, point.y);
	}
	TRACE("\n");
	 */
	touchEvent = BUTTON_MOVED;
}
#pragma mark -

- (void)dealloc
{
	[noteDelegate release];
	[super dealloc];
}

@end
