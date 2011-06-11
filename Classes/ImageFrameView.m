//
//  ImageFrameView.m
//  GeoJournal
//
//  Created by Jae Han on 12/7/10.
//  Copyright 2010 Home. All rights reserved.
//
#import "GeoJournalHeaders.h"
#import "ImageFrameView.h"


@implementation ImageFrameView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
		self.backgroundColor = [UIColor blackColor];
		self.opaque = YES;
		self.clearsContextBeforeDrawing = YES;		
    }
    return self;
}

-(void)drawInContext:(CGContextRef)context
{
	// Drawing with a white stroke color
	//CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	// And drawing with a blue fill color
	//CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1.0);
	// Draw them with a 2.0 stroke width so they are a bit more visible.
	//CGContextSetLineWidth(context, 2.0);
	
	// Add Rect to the current path, then stroke it
	//CGContextAddRect(context, _rect);
	//CGContextStrokePath(context);
	
	// Stroke Rect convenience that is equivalent to above
	//CGContextStrokeRect(context, _rect);
	
	// Stroke rect convenience equivalent to the above, plus a call to CGContextSetLineWidth().
	//CGContextStrokeRectWithWidth(context, _rect, 10.0);
	// Demonstate the stroke is on both sides of the path.
	//CGContextSaveGState(context);
	CGContextSetRGBStrokeColor(context, 0.4667, 0.4667, 0.4667, 1.0);
	CGContextStrokeRectWithWidth(context, _rect, 5.0);
	//CGContextRestoreGState(context);
	
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
	DEBUG_RECT("drawRect", rect);
	memcpy(&_rect, &rect, sizeof(rect));
	[self drawInContext:UIGraphicsGetCurrentContext()];
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
	NSTimeInterval pressEnd = 0.0;
	CGPoint point;
	
	for (UITouch *loc in touches){
		point = [loc locationInView:loc.view];
		pressEnd = loc.timestamp;
		//TRACE("%s, x: %f, y: %f\n", __func__, point.x, point.y);
	}
	if (_press_status == PRESS_BEGIN && (pressEnd - _timestamp) <= 1) {
		// Must be selected.
		[delegate openFullView:point];
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

- (void)dealloc {
    //[super dealloc];
}


@end
