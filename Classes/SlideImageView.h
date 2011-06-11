//
//  SlideImageView.h
//  JeJuSite
//
//  Created by Jae Han on 8/21/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GeoJournalHeaders.h"

@protocol SlideImageViewDelegate;

@interface SlideImageView : UIScrollView {
	id <SlideImageViewDelegate>	delegate;
	
	@private
	PRESS_STATUS				_press_status;
	NSTimeInterval				_timestamp;
}

@property (nonatomic, assign) id <SlideImageViewDelegate>	delegate;

@end

@protocol SlideImageViewDelegate <NSObject>

@optional
- (void)selectImage:(CGPoint)point;

@end