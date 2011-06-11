//
//  ImageContrainer.m
//  JeJuSite
//
//  Created by Jae Han on 7/14/10.
//  Copyright 2010 Home. All rights reserved.
//
#import "GeoJournalHeaders.h"
#import "ImageContainer.h"


@implementation ImageContainer

@synthesize button;
@synthesize image;
@synthesize imageView;
@synthesize activity;
@synthesize selectionRectangle;

- (void)dealloc
{
	TRACE_HERE;
	[button release];
	[imageView release];
	[image release];
	[activity release];
	[selectionRectangle release];
	
	[super dealloc];
}
@end
