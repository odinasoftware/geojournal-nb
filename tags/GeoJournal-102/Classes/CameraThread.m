//
//  CameraThread.m
//  GeoJournal
//
//  Created by Jae Han on 9/5/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "CameraThread.h"
#import "GeoJournalHeaders.h"

static CameraThread	*sharedCameraThreadController = nil;

@implementation CameraThread

@synthesize _cameraController;
@synthesize _viewController;

+(CameraThread*)sharedCameraControllerInstance
{
	@synchronized (self) {
		if (sharedCameraThreadController == nil) {
			[[self alloc] init];
		}
	}
	return sharedCameraThreadController;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized (self) { 
		if (sharedCameraThreadController == nil) { 
			sharedCameraThreadController = [super allocWithZone:zone]; 
			return sharedCameraThreadController; // assignment and return on first allocation 
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

- (id)init
{
	if (self = [super init]) {
		doSomething = [[NSCondition alloc] init];
	}
	
	return self;
}

- (void)main
{
	TRACE("Camera thread started.\n");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	for (;;) {
		[doSomething lock];
		[doSomething wait];
		[doSomething unlock];
		NSAutoreleasePool *subpool = [[NSAutoreleasePool alloc] init];
		
		if (self._viewController && self._cameraController) {
			[self._viewController presentModalViewController:self._cameraController animated:YES];
		}
		
		[subpool release];
	}
	
	[pool release];
}

- (void)startCameraView:(UIViewController*)controller withPicker:(UIImagePickerController*)picker
{
	TRACE_HERE;
	self._viewController = controller;
	self._cameraController = picker;
	[doSomething signal];
}

- (void)dealloc
{
	[_cameraController release];
	[_viewController release];
	[super dealloc];
}

@end
