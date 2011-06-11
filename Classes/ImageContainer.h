//
//  ImageContrainer.h
//  JeJuSite
//
//  Created by Jae Han on 7/14/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ImageContainer : NSObject {
	UIImage					*image;
	UIImageView				*imageView;
	UIButton				*button;
	UIView					*selectionRectangle;
	UIActivityIndicatorView	*activity;
}

@property (nonatomic, retain) UIButton					*button;
@property (nonatomic, retain) UIImage					*image;
@property (nonatomic, retain) UIImageView				*imageView;
@property (nonatomic, retain) UIView					*selectionRectangle;
@property (nonatomic, retain) UIActivityIndicatorView	*activity;

@end
