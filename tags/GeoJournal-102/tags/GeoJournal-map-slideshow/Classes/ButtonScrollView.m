//
//  ButtonScrollView.m
//  GeoJournal
//
//  Created by Jae Han on 7/13/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "ButtonScrollView.h"
#import "GeoJournalHeaders.h"

@implementation ButtonScrollView

- (void)viewDidLoad
{
	//self.delegate = self;
	if ([self canBecomeFirstResponder] == YES) {
		TRACE("%s, becomre the first responder.\n", __func__);
		[self becomeFirstResponder];
	}
	self.exclusiveTouch = YES;
	self.multipleTouchEnabled = YES;
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
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
}


@end
