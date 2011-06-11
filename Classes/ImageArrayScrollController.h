//
//  ImageArrayScrollController.h
//  JeJuSite
//
//  Created by Jae Han on 8/21/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlideImageView.h"

@class SlideImageView;

@interface ImageArrayScrollController : UIViewController <UIScrollViewDelegate, SlideImageViewDelegate> {
	IBOutlet SlideImageView		*scrollView;
		
	NSArray						*imageArray;
	NSMutableArray				*_imageContainerArray;
	NSString					*firstPicturename;
	NSInteger					_selectedIndex;
}

@property (nonatomic, retain) SlideImageView	*scrollView;
@property (nonatomic, retain) NSArray			*imageArray;
@property (nonatomic, retain) NSMutableArray	*imageContainerArray;
@property (nonatomic, retain) NSString			*firstPicturename;

- (void)startLoadingImages;
- (NSInteger)findImgIndex:(CGPoint)point;
- (void)addImage:(UIImage*)image;
- (void)displayImages;
- (NSString*)getSelectedImageName;

@end

