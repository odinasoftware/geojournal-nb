//
//  GeoSession.m
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "GeoSession.h"
#import "FBConnect/FBConnect.h"
#import "GeoJournalHeaders.h"
#import "FacebookConnect.h"

static GeoSession	*sharedGeoSession = nil;

@implementation GeoSession

@synthesize fbSession;
@synthesize fbUID;
@synthesize fbUserName;
@synthesize gotExtendedPermission;
@synthesize fbConnectAgent;

+ (GeoSession*)sharedGeoSessionInstance
{
	//@synchronized (self) {
	if (sharedGeoSession == nil) {
		[[self alloc] init];
	}
	//}
	return sharedGeoSession;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized (self) { 
		if (sharedGeoSession == nil) { 
			sharedGeoSession = [super allocWithZone:zone]; 
			return sharedGeoSession;
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

+ (FBSession*)getFBSession:(id)delegate
{
	GeoSession *session = [GeoSession sharedGeoSessionInstance];
	
	if (session.fbSession == nil)
		session.fbSession = [FBSession sessionForApplication:@"5bfecb7edf25fd2d24dc76bcfc3f5d87" secret:@"f7396379034249a0754be1bd6df820bc" delegate:delegate];
	
	return session.fbSession;
}

+ (FacebookConnect*)getFBAgent
{
	GeoSession *session = [GeoSession sharedGeoSessionInstance];
	FacebookConnect *agent = session.fbConnectAgent;
	
	if (agent == nil) {
		FacebookConnect *a = [[FacebookConnect alloc] init];
		session.fbConnectAgent = a;
		[a release];
		
		agent = session.fbConnectAgent;
	}
	
	return agent;
}

-(id)init 
{
	self = [super init];
	if (self) {
		fbUID = 0;
		fbConnectAgent = nil;
	}
	
	return self;
}

#pragma mark EXTENDED PERMISSION
- (void)getExtendedPermission:(id)object 
{
	FBPermissionDialog* dialog = [[[FBPermissionDialog alloc] init] autorelease];
	if (object)
		dialog.delegate = object;
	else
		dialog.delegate = self;
	dialog.permission = @"status_update";
	[dialog show];	
}

- (void)request:(FBRequest*)request didLoad:(id)result 
{
	TRACE("%s, %s returns: %d\n", __func__, [request.method UTF8String], result);
	NSArray* users = result;
	if ([users count] > 0) {
		NSDictionary* user = [users objectAtIndex:0];
		self.fbUserName = [user objectForKey:@"name"];
		// Show user name
		NSLog(@"%s, Query returned %@", __func__, self.fbUserName);
	}
	else {
		NSLog(@"%s, Fail to get user name:\n", __func__);
	}
}

- (void)dialogDidSucceed:(FBDialog*)dialog 
{
	TRACE("%s, got the extended permission.\n", __func__);
	gotExtendedPermission = YES;
}

- (void)dialogDidCancel:(FBDialog*)dialog 
{
	TRACE("%s, user declines the extended permission.\n", __func__);
	gotExtendedPermission = NO;
}
#pragma mark -

- (void)dealloc
{
	[fbConnectAgent release];
	[fbUserName release];
	[fbSession release];
	[super dealloc];
}


@end
