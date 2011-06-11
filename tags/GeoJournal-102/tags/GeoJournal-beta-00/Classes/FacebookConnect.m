//
//  FacebookConnect.m
//  GeoJournal
//
//  Created by Jae Han on 9/5/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "FacebookConnect.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "GeoDatabase.h"
#import "GeoSession.h"
#import "FBConnect/FBFeedDialog.h"

#define GEO_JOURNAL_TEMPLATE_BUNDLE_ID		154941700409

extern NSString *getImageHrefForFacebook(float latitude, float longitude);

@implementation FacebookConnect

@synthesize journalToPost;
@synthesize imageForJournal;
@synthesize _alertView;

- (id)init
{
	if (self = [super init]) {
		_fbCallType = FB_REQUEST_NONE;
	}
	
	return self;
}

/*
 * The templateData property is a string and cannot contain any carriage returns. 
 * It needs to be a JSON-encoded string using the format described in Template Data. 
 * Reserved tokens contain more than one JSON value and can be tricky to add to templateData.
 * 
 * JSON object
 * An object is an unordered set of name/value pairs. An object begins with { (left brace) and ends with } (right brace). 
 * Each name is followed by : (colon) and the name/value pairs are separated by , (comma).
 */
/*
 * Facebook Publish structure 
 */
- (void)publishToFacebook:(NSString*)image_url
{
	FBFeedDialog* dialog = [[FBFeedDialog alloc] init];
	dialog.delegate = self;
	dialog.templateBundleId = GEO_JOURNAL_TEMPLATE_BUNDLE_ID;
	NSString *data = nil;
	
	if (image_url) {
		data = [[NSString alloc] initWithFormat:@"{\"geo_title\": \"%@\", \"geo_message\":\"%@\", \"geo_address\":\"%@\", \"images\":[{\"src\":\"%@\",\"href\":\"%@\"}]}", 
				([self.journalToPost title]==nil?@"No title":[self.journalToPost title]), 
				([self.journalToPost text]==nil?@"No message":[self.journalToPost text]), 
				([self.journalToPost address]==nil?@"No location info available":[self.journalToPost address]),
				image_url, 
				getImageHrefForFacebook([[self.journalToPost latitude] floatValue], [[self.journalToPost longitude] floatValue])];
	}
	else {
		data = [[NSString alloc] initWithFormat:@"{\"geo_title\": \"%@\", \"geo_message\":\"%@\", \"geo_address\":\"%@\"}", 
				([self.journalToPost title]==nil?@"No title":[self.journalToPost title]), 
				([self.journalToPost text]==nil?@"No message":[self.journalToPost text]), 
				([self.journalToPost address]==nil?@"No location info available":[self.journalToPost address])];
	}
	
	_fbCallType = FB_UPLOAD_STORY;
	dialog.templateData = data;
	[dialog show];		
	[data release];
	[dialog release];
}

- (FBRequest*)getRequest
{
	return [FBRequest requestWithDelegate:self];
}

- (void)publishPhotoToFacebook
{
	if (self.imageForJournal) {
		NSMutableDictionary *args = [[[NSMutableDictionary alloc] init] autorelease];
		
		[args setObject:self.imageForJournal forKey:@"image"];    // 'images' is an array of 'UIImage' objects
		FBRequest *uploadPhotoRequest = [self getRequest];
		_fbCallType = FB_UPLOAD_PICTURE;
		[uploadPhotoRequest call:@"facebook.photos.upload" params:args];
	}
	else {
		NSLog(@"%s, image is not available.", __func__);
	}
}

- (void)performDismiss:(NSTimer*)timer 
{
	[self._alertView dismissWithClickedButtonIndex:0 animated:NO];
}

- (void)showProgress
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Publish" message:@"Syncing with Facebook. Please wait..." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	self._alertView = alert;
	[alert release];
	[NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(performDismiss:) userInfo:nil repeats:NO];
	[alert show];
}

- (void)publishToFacebookForJournal:(Journal*)j withImage:(UIImage*)image 
{
	TRACE_HERE;
	
	self.journalToPost = j;
	self.imageForJournal = image;
	
	if ([GeoSession sharedGeoSessionInstance].fbUID == 0) {
		FBLoginDialog* dialog = [[FBLoginDialog alloc] initWithSession:[GeoSession getFBSession:self]];
		_fbCallType = FB_REQUEST_LOGIN;
		[dialog show];
		[dialog release];
	}
	else if ([GeoSession sharedGeoSessionInstance].gotExtendedPermission == NO) {
		_fbCallType = FB_REQUEST_PERMISSION;
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(getFBExtendedPermission:) withObject:self waitUntilDone:NO];
	} 
	else {
		[self showProgress];
		[self publishPhotoToFacebook];
		//[self publishToFacebook];
	}
	
}

#pragma mark FBSession delegate
- (void)session:(FBSession*)session didLogin:(FBUID)uid {
	NSLog(@"User with id %lld logged in.", uid);
	[GeoSession sharedGeoSessionInstance].fbUID = uid;
	//[self getUserName];
	
	if (_fbCallType == FB_REQUEST_LOGIN) {
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(getFBUserName:) withObject:nil waitUntilDone:NO];	
		_fbCallType = FB_REQUEST_PERMISSION;
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(getFBExtendedPermission:) withObject:self waitUntilDone:YES];
		// Wait for the permission is granted.
	}
}
#pragma mark -
#pragma mark FBRequest delegate

- (void)request:(FBRequest*)request didLoad:(id)result 
{
	TRACE("%s, %s, call: %d, request succeeded. %d\n", __func__, [request.method UTF8String], _fbCallType, result);
	
	if (_fbCallType == FB_UPLOAD_PICTURE) {
		NSDictionary* users = result;
		
		NSString* url = [users objectForKey:@"src"];
		NSString* url_small = [users objectForKey:@"src_small"];
		// Show user name
		
		TRACE("%s, src: %s, src_small: %s\n", __func__, [url UTF8String], [url_small UTF8String]);
		NSLog(@"Query returned %@", [GeoSession sharedGeoSessionInstance].fbUserName);
		
		if (url) {
			[self publishToFacebook:url];
		}
	}
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error 
{
	NSLog(@"%s, request failed. %@", __func__, error);
}

#pragma mark -
#pragma mark FBDialog delegate
/* Facebook picture upload.
 http://forum.developers.facebook.com/viewtopic.php?id=30467
 */
- (void)dialogDidSucceed:(FBDialog*)dialog
{
	TRACE_HERE;
	if (_fbCallType == FB_REQUEST_PERMISSION) {
		// has to be abel to differentiate between FB 
		// Permission for uploading picture succeeded, now upload the picture.
		[GeoSession sharedGeoSessionInstance].gotExtendedPermission = YES;
		[self publishPhotoToFacebook];
	}
}

- (void)dialogDidCancel:(FBDialog*)dialog
{
	TRACE_HERE;
}

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError*)error
{
	TRACE_HERE;
	NSLog(@"%s, %@", __func__, error);
}
#pragma mark -

- (void)dealloc
{
	[imageForJournal release];
	[journalToPost release];
	[_alertView release];
	[super dealloc];
}

@end
