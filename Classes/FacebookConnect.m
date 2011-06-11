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

#define GEO_JOURNAL_TEMPLATE_BUNDLE_ID		154941700409
#define LINE_FEED							0x0A
#define CARRIAGE_RETURN						0x0D
#define BLANK								@" "

extern NSString *getImageHrefForFacebook(float latitude, float longitude);

NSString *getJASONSafeString(NSString *string) {
	/*
	NSMutableData *stringData = [[NSMutableData alloc] initWithCapacity:[string length]];
	
	char *data = (char*) [string UTF8String];
	
	for (int i=0; i<[string length]; ++i) {
		if (data[i] != LINE_FEED && data[i] != CARRIAGE_RETURN) {
			[stringData appendBytes:&data[i] length:1];
		}
	}
	
	NSString *safe = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
	 */
	NSMutableString *safe = [[NSMutableString alloc] initWithCapacity:[string length]];
	NSRange subRange = NSMakeRange(0, [string length]);
	NSRange searchRange = NSMakeRange(0, [string length]);
	NSRange range;
	
	do {
		range = [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSCaseInsensitiveSearch range:searchRange];
		if (range.location == NSNotFound) {

			[safe appendString:[string substringWithRange:searchRange]];
		}
		else {
			subRange.location = searchRange.location;
			subRange.length = range.location - searchRange.location;
			[safe appendString:[string substringWithRange:subRange]];
			[safe appendString:BLANK];

			searchRange.location = range.location+1;
			searchRange.length = [string length] - searchRange.location;
		}
		
	} while (range.location != NSNotFound && searchRange.location < [string length]);
	
	TRACE("%s, %s\n", __func__, [safe UTF8String]);
	return safe;
}

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
	SBJSON *jsonWriter = [[SBJSON new] autorelease];
	
	NSString *caption = nil;
	
	caption = [[NSString alloc] initWithFormat:@"%@ at %@", [self.journalToPost title]==nil?@"No title":[self.journalToPost title],
			   [self.journalToPost address]==nil?@"No location info available":[self.journalToPost address]];
	/*
	NSString *caption = nil;
	
	caption = [[NSString alloc] initWithFormat:@"%@ at %@", [self.journalToPost title]==nil?@"No title":[self.journalToPost title],
			   [self.journalToPost address]==nil?@"No location info available":[self.journalToPost address]];
	
	//NSDictionary* actionLinks = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
	//													   @"Always Running",@"text",@"http://itsti.me/",@"href", nil], nil];
	
	//NSString *actionLinksStr = [jsonWriter stringWithObject:actionLinks];
	NSDictionary* attachment = [NSDictionary dictionaryWithObjectsAndKeys:
								caption, @"caption",
								([self.journalToPost text]==nil?@"No message":[self.journalToPost text]), @"description",
								image_url, @"href", nil];
	NSString *attachmentStr = [jsonWriter stringWithObject:attachment];
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									attachmentStr, @"feed",
									nil];
	
	NSMutableDictionary *params2 = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									[jsonWriter stringWithObject:caption], @"message", nil];
									//[jsonWriter stringWithObject:@"Message test"], @"description",
									// [jsonWriter stringWithObject:image_url], @"picture", nil];
	*/
	
	/* Image attachment does not work anymore, 12/16/10.
	NSDictionary *image = [NSDictionary dictionaryWithObjectsAndKeys:
						   @"image", @"type",
						   image_url, @"src", nil];
	NSArray *media = [NSArray arrayWithObjects:image, nil];
	 */
	NSDictionary* actionLinks = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
														   @"Picture post",@"text",
														   image_url,@"href", nil], nil];
	
	NSString *actionLinksStr = [jsonWriter stringWithObject:actionLinks];
	NSMutableDictionary* attachment = [[NSMutableDictionary alloc] initWithCapacity:2];
	
	if ([self.journalToPost title]) {
		[attachment setObject:[self.journalToPost text] forKey:@"caption"];
	}
	if ([self.journalToPost description]) {
		[attachment setObject:[self.journalToPost description] forKey:@"description"];
	}
		
	NSString *attachmentStr = [jsonWriter stringWithObject:attachment];
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   @"Share on Facebook via iGeoJournal",  @"user_message_prompt",
								   actionLinksStr, @"action_links",
								   attachmentStr, @"attachment",
								   nil];
	
	[[GeoSession sharedGeoSessionInstance].facebook dialog:@"stream.publish"
												 andParams:params
											   andDelegate:self];
	[attachment release];	 

	//[caption release];
	
	//NSString *graphPath = [[NSString alloc] initWithFormat:@"%@/feed", [GeoSession sharedGeoSessionInstance].fbUID];
	//[[GeoSession sharedGeoSessionInstance].facebook requestWithGraphPath:graphPath
	//														   andParams:params2 
	//													   andHttpMethod:@"POST"
	//														 andDelegate:self];
	//
	//[graphPath release];
	
	
#if 0
	FBStreamDialog* dialog = [[FBStreamDialog alloc] init];
	dialog.delegate = self;
	//dialog.templateBundleId = GEO_JOURNAL_TEMPLATE_BUNDLE_ID;
	NSString *data = nil;
	
	NSString *caption = nil;
	
	caption = [[NSString alloc] initWithFormat:@"%@ at %@", [self.journalToPost title]==nil?@"No title":[self.journalToPost title],
														[self.journalToPost address]==nil?@"No location info available":[self.journalToPost address]];
	
	if (image_url) {
		data = [[NSString alloc] initWithFormat:@"{\"caption\": \"%@\", \"description\":\"%@\", \"media\":[{\"type\":\"image\",\"src\":\"%@\",\"href\":\"%@\"}]}", 
				caption,
				([self.journalToPost text]==nil?@"No message":getJASONSafeString([self.journalToPost text])), 
				image_url, 
				getImageHrefForFacebook([[self.journalToPost latitude] floatValue], [[self.journalToPost longitude] floatValue])];
	}
	else {
		data = [[NSString alloc] initWithFormat:@"{\"caption\": \"%@\", \"description\":\"%@\"}", 
				caption,
				([self.journalToPost text]==nil?@"No message":getJASONSafeString([self.journalToPost text]))];
	}
	
	_fbCallType = FB_UPLOAD_STORY;
	dialog.attachment = data;
	[dialog show];		
	[data release];
	[dialog release];
	[caption release];
#endif
}

- (FBRequest*)getRequest
{
	return [FBRequest requestWithDelegate:self];
}

- (void)publishPhotoToFacebook
{
	if (self.imageForJournal) {
		NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									   self.imageForJournal, @"picture",
									   nil];
		
		[[GeoSession sharedGeoSessionInstance].facebook requestWithMethodName:@"photos.upload"
																andParams:params
																andHttpMethod:@"POST"
																  andDelegate:self];
		//[[GeoSession sharedGeoSessionInstance].facebook requestWithGraphPath:@"me" 
		//														   andParams:params
		//													   andHttpMethod:@"POST"
		//														 andDelegate:self];

				
		//NSMutableDictionary *args = [[[NSMutableDictionary alloc] init] autorelease];
		
		//[args setObject:self.imageForJournal forKey:@"image"];    // 'images' is an array of 'UIImage' objects
		//FBRequest *uploadPhotoRequest = [self getRequest];
		//_fbCallType = FB_UPLOAD_PICTURE;
		[params release];
		
		//[uploadPhotoRequest call:@"facebook.photos.upload" params:params dataParam:(NSData*)self.imageForJournal];
	}
	else {
		NSLog(@"%s, image is not available.", __func__);
		[self publishToFacebook:nil];
	}
	self.imageForJournal = nil;
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

- (void)loginToFacebookWithNotification:(BOOL)notify
{
	_notifySuccess = notify;

	FBLoginDialog* dialog = [[FBLoginDialog alloc] initWithSession:[GeoSession getFBSession:self]];
	_fbCallType = FB_REQUEST_LOGIN;
	dialog.delegate = self;
	[dialog show];
	[dialog release];	
}

- (void)publishToFacebookForJournal:(Journal*)j withImage:(UIImage*)image 
{
	TRACE_HERE;
	
	self.journalToPost = j;
	self.imageForJournal = image;
	[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(getFBExtendedPermission:) withObject:self waitUntilDone:NO];
	[[GeoSession sharedGeoSessionInstance] publishPhotoToFacebook];
	/*
	if ([GeoSession sharedGeoSessionInstance].fbUID == 0) {
		[self loginToFacebookWithNotification:NO];
	}
	else if ([GeoSession sharedGeoSessionInstance].gotExtendedPermission == NO) {
		_fbCallType = FB_REQUEST_PERMISSION;
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(getFBExtendedPermission:) withObject:self waitUntilDone:NO];
	} 
	else {
		[self showProgress];
		[self publishPhotoToFacebook];
	}
	*/
}

#pragma mark FBSession delegate
/*
- (void)session:(FBSession*)session didLogin:(FBUID)uid {
	NSLog(@"%s, user with id %lld logged in.", __func__, uid);
	[GeoSession sharedGeoSessionInstance].fbUID = uid;
	//[self getUserName];
	
	if (_fbCallType == FB_REQUEST_LOGIN) {
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(getFBUserName:) withObject:nil waitUntilDone:NO];	
		_fbCallType = FB_REQUEST_PERMISSION;
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(getFBExtendedPermission:) withObject:self waitUntilDone:YES];
		// Wait for the permission is granted.
	}
}
 */
#pragma mark -
#pragma mark FBRequest delegate

- (void)request:(FBRequest*)request didLoad:(id)result 
{
	if ([result isKindOfClass:[NSArray class]]) {
		result = [result objectAtIndex:0];
	}
	
	for (NSString *k in [result allKeys]){
		TRACE("keys: %s\n", [k UTF8String]);
	}
	NSString *url = [result objectForKey:@"link"];
	//NSString *url_small = [results objectForKey:@"src_small"];
	[self publishToFacebook:url];
#if 0
	//TRACE("%s, %s, call: %d, request succeeded. %d\n", __func__, [request.method UTF8String], _fbCallType, result);
	
	if (_fbCallType == FB_UPLOAD_PICTURE) {
		NSDictionary* users = [result objectAtIndex:0];
		
		NSString* url = [users objectForKey:@"src"];
		NSString* url_small = [users objectForKey:@"src_small"];
		// Show user name
		
		TRACE("%s, src: %s, src_small: %s\n", __func__, [url UTF8String], [url_small UTF8String]);
		//NSLog(@"Query returned %@", [GeoSession sharedGeoSessionInstance].fbUserName);
		
		if (url) {
			[self publishToFacebook:url];
		}
	}
#endif
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error 
{
	NSLog(@"%s, request failed. %@", __func__, error);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook error" message:[error description]
												   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
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
		//[GeoSession sharedGeoSessionInstance].gotExtendedPermission = YES;
		if (_notifySuccess) {
			// Notify to ConnectView
			[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(notifyLoggedin:) withObject:nil waitUntilDone:NO];	
		}
		else {
			// This is not login request.
			[self publishPhotoToFacebook];
		}
	}
}

- (void)dialogDidCancel:(FBDialog*)dialog
{
	TRACE_HERE;
	if (_fbCallType == FB_REQUEST_LOGIN || _fbCallType == FB_REQUEST_PERMISSION) {
		[[GeoSession sharedGeoSessionInstance] logoutFBSessionWithNotification:YES];
	}
}

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError*)error
{
	TRACE_HERE;
	NSLog(@"%s, %@", __func__, error);
	[self showFacebookConnectError:[error localizedDescription]];
}
- (void)dialogDidComplete:(FBDialog *)dialog {
	TRACE_HERE;
}
#pragma mark -

- (void)showFacebookConnectError:(NSString*)description
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook error" message:description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (void)dealloc
{
	[imageForJournal release];
	[journalToPost release];
	[_alertView release];
	[super dealloc];
}

@end
