//
//  ImageFrameView.h
//  GeoJournal
//
//  Created by Jae Han on 12/7/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GeoJournalHeaders.h"

@protocol OpenFullViewDelegate;

@interface ImageFrameView : UIView {
	id <OpenFullViewDelegate>	delegate;
	CGRect		_rect;
	
	@private
	PRESS_STATUS				_press_status;
	NSTimeInterval				_timestamp;
}

-(void)drawInContext:(CGContextRef)context;

@property (nonatomic, assign) id<OpenFullViewDelegate> delegate;

@end

@protocol OpenFullViewDelegate <NSObject>

@optional	
- (void)openFullView:(CGPoint)point;

@end

