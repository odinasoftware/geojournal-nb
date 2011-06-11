//
//  GeoSession.m
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "GeoSession.h"
#import "FBConnect/FBConnect.h"

static GeoSession	*sharedGeoSession = nil;

@implementation GeoSession

@synthesize fbSession;
@synthesize fbUID;
@synthesize fbUserName;

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
		session.fbSession = [FBSession sessionForApplication:@"41c28e0cd58cc3a5b47ed1179a0a694d" secret:@"1ea51b60620132526e046beeff5aad92" delegate:delegate];
	
	return session.fbSession;
}

-(id)init 
{
	self = [super init];
	if (self) {
		fbUID = 0;
	}
	
	return self;
}



- (void)dealloc
{
	[fbUserName release];
	[fbSession release];
	[super dealloc];
}


@end
