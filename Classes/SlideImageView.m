//
//  SlideImageView.m
//  JeJuSite
//
//  Created by Jae Han on 8/21/10.
//  Copyright 2010 Home. All rights reserved.
//
#import "GeoJournalHeaders.h"
#import "SlideImageView.h"


@implementation SlideImageView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		TRACE("%s, width: %f, height: %f\n", __func__, frame.size.width, frame.size.height);
    }
    return self;
}

#pragma mark TOUCH events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
	_press_status = PRESS_BEGIN;
	for (UITouch *loc in touches){
		//CGPoint point = [loc locationInView:loc.view];
		_timestamp = loc.timestamp;
		//TRACE("%s, x: %f, y: %f, w: %f\n", __func__, point.x, point.y, ((UIScrollView*)loc.view).contentSize.width);
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
	_press_status = PRESS_CANCEL;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
	NSTimeInterval pressEnd;
	CGPoint point;
	
	for (UITouch *loc in touches){
		point = [loc locationInView:loc.view];
		pressEnd = loc.timestamp;
		//TRACE("%s, x: %f, y: %f\n", __func__, point.x, point.y);
	}
	if (_press_status == PRESS_BEGIN && (pressEnd - _timestamp) <= 1) {
		// Must be selected.
		[delegate selectImage:point];
	}
	else {
		_press_status = PRESS_END;
	}

}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
	_press_status = PRESS_DRAG;
}
#pragma mark -

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [super dealloc];
}


@end
