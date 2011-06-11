/*
 * Copyright 2009 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0

 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

#import "FBConnect/FBRequest.h"
#import "FBConnect/FBSession.h"
#import "FBXMLHandler.h"
#import <CommonCrypto/CommonDigest.h>
#import "GeoJournalHeaders.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static NSString* kAPIVersion = @"1.0";
static NSString* kAPIFormat = @"XML";
static NSString* kUserAgent = @"FacebookConnect";
static NSString* kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";

static const NSTimeInterval kTimeoutInterval = 180.0;

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FBRequest

@synthesize delegate = _delegate, url = _url, method = _method, params = _params,
  userInfo = _userInfo, timestamp = _timestamp;

///////////////////////////////////////////////////////////////////////////////////////////////////
// class public

+ (FBRequest*)request {
  return [self requestWithSession:[FBSession session]];
}

+ (FBRequest*)requestWithDelegate:(id<FBRequestDelegate>)delegate {
  return [self requestWithSession:[FBSession session] delegate:delegate];
}

+ (FBRequest*)requestWithSession:(FBSession*)session {
  return [[[FBRequest alloc] initWithSession:session] autorelease];
}

+ (FBRequest*)requestWithSession:(FBSession*)session delegate:(id<FBRequestDelegate>)delegate {
  FBRequest* request = [[[FBRequest alloc] initWithSession:session] autorelease];
  request.delegate = delegate;
  return request;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (NSString*)md5HexDigest:(NSString*)input {
  const char* str = [input UTF8String];
  unsigned char result[CC_MD5_DIGEST_LENGTH];
  CC_MD5(str, strlen(str), result);

  return [NSString stringWithFormat:
    @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
    result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
    result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
  ];
}

- (BOOL)isSpecialMethod {
  return [_method isEqualToString:@"facebook.auth.getSession"]
        || [_method isEqualToString:@"facebook.auth.createToken"];
}

- (NSString*)urlForMethod:(NSString*)method {
  return _session.apiURL; 
}

- (NSString*)generateGetURL {
  NSURL* parsedURL = [NSURL URLWithString:_url];
  NSString* queryPrefix = parsedURL.query ? @"&" : @"?";

  NSMutableArray* pairs = [NSMutableArray array];
  for (NSString* key in [_params keyEnumerator]) {
    NSString* value = [_params objectForKey:key];
    [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
  }
  NSString* params = [pairs componentsJoinedByString:@"&"];
  
  return [NSString stringWithFormat:@"%@%@%@", _url, queryPrefix, params];
}

- (NSString*)generateCallId {
  return [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
}

/*
 asically the parameter key for the photo was being included in the sig, which it should not. 
 http://forum.developers.facebook.com/viewtopic.php?id=30467
 
 */
- (NSString*)generateSig {
  NSMutableString* joined = [NSMutableString string]; 

  NSArray* keys = [_params.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
  for (id obj in [keys objectEnumerator]) {
	  
    id value = [_params valueForKey:obj];
    if ([value isKindOfClass:[NSString class]]) {
		[joined appendString:obj];
		[joined appendString:@"="];
      [joined appendString:value];
    }
  }

  if ([self isSpecialMethod]) {
    if (_session.apiSecret) {
      [joined appendString:_session.apiSecret];
    }
  } else if (_session.sessionSecret) {
    [joined appendString:_session.sessionSecret];
  } else if (_session.apiSecret) {
    [joined appendString:_session.apiSecret];
  }
  
  return [self md5HexDigest:joined];
}

- (NSMutableData*)generatePostBody {
  NSMutableData* body = [NSMutableData data];
  NSString* endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];

  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", kStringBoundary]
    dataUsingEncoding:NSUTF8StringEncoding]];
  
  for (id key in [_params keyEnumerator]) {
    if (![[_params objectForKey:key] isKindOfClass:[UIImage class]]) {
      [body appendData:[[NSString
        stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key]
          dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:[[_params valueForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];        
    }
  }

  for (id key in [_params keyEnumerator]) {
    if ([[_params objectForKey:key] isKindOfClass:[UIImage class]]) {
      UIImage* image = [_params objectForKey:key];
      NSData* imageData = UIImageJPEGRepresentation(image, 0.75);
      
      [body appendData:[[NSString
        stringWithFormat:@"Content-Disposition: form-data; filename=\"photo\"\r\n"]
          dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:[[NSString
        stringWithString:@"Content-Type: image/jpeg\r\n\r\n"]
          dataUsingEncoding:NSUTF8StringEncoding]];  
      [body appendData:imageData];
      [body appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
    }
  }
  
  FBLOG2(@"Sending %s", [body bytes]);
  return body;
}

- (id)parseXMLResponse:(NSData*)data error:(NSError**)error {
  FBXMLHandler* handler = [[[FBXMLHandler alloc] init] autorelease];
  NSXMLParser* parser = [[[NSXMLParser alloc] initWithData:data] autorelease];
  parser.delegate = handler;
  [parser parse];

  if (handler.parseError) {
    if (error) {
      *error = [[handler.parseError retain] autorelease];
    }
    return nil;
  } else if ([handler.rootName isEqualToString:@"error_response"]) {
    NSDictionary* errorDict = handler.rootObject;
    NSInteger code = [[errorDict objectForKey:@"error_code"] intValue];
    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
      [errorDict objectForKey:@"error_msg"], NSLocalizedDescriptionKey,
      [errorDict objectForKey:@"request_args"], @"request_args",
      nil];
    if (error) {
      *error = [NSError errorWithDomain:FBAPI_ERROR_DOMAIN code:code userInfo:info];
    }
    return nil;
  } else {
    return [[handler.rootObject retain] autorelease];
  }
}

- (void)failWithError:(NSError*)error {
  if ([_delegate respondsToSelector:@selector(request:didFailWithError:)]) {
    [_delegate request:self didFailWithError:error];
  }
}

- (void)handleResponseData:(NSData*)data {
  FBLOG2(@"DATA: %s", data.bytes);
  NSError* error = nil;
  id result = [self parseXMLResponse:data error:&error];
  if (error) {
    [self failWithError:error];
  } else if ([_delegate respondsToSelector:@selector(request:didLoad:)]) {
    [_delegate request:self didLoad:result];
  }
}

- (void)connect {
  FBLOG(@"Connecting to %@ %@", _url, _params);

  if ([_delegate respondsToSelector:@selector(requestLoading:)]) {
    [_delegate requestLoading:self];
  }

  NSString* url = _method ? _url : [self generateGetURL];
  NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                  timeoutInterval:kTimeoutInterval];
  [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
  
  if (_method) {
    [request setHTTPMethod:@"POST"];
    
    NSString* contentType = [NSString
      stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];

    [request setHTTPBody:[self generatePostBody]];
  }
  
  _timestamp = [[NSDate date] retain];
  _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithSession:(FBSession*)session {
  _session = session;
  _delegate = nil;
  _url = nil;
  _method = nil;
  _params = nil;
  _userInfo = nil;
  _timestamp = nil;
  _connection = nil;
  _responseText = nil;
  return self;
}

- (void)dealloc {
	TRACE_HERE;
  [_connection cancel];
  [_connection release];
  [_responseText release];
  [_url release];
  [_method release];
  [_params release];
  [_userInfo release];
  [_timestamp release];
  [super dealloc];
}

- (NSString*)description {
  return [NSString stringWithFormat:@"<FBRequest %@>", _method ? _method : _url];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// NSURLConnectionDelegate
 
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
  _responseText = [[NSMutableData alloc] init];

  NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
  if ([_delegate respondsToSelector:@selector(request:didReceiveResponse:)]) {    
    [_delegate request:self didReceiveResponse:httpResponse];
  }
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
  [_responseText appendData:data];
}

- (NSCachedURLResponse*)connection:(NSURLConnection*)connection
    willCacheResponse:(NSCachedURLResponse*)cachedResponse {
  return nil;
}

-(void)connectionDidFinishLoading:(NSURLConnection*)connection {
  [self handleResponseData:_responseText];
  
  [_responseText release];
  _responseText = nil;
  [_connection release];
  _connection = nil;
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {  
  [self failWithError:error];

  [_responseText release];
  _responseText = nil;
  [_connection release];
  _connection = nil;
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (BOOL)loading {
  return !!_connection;
}

- (void)call:(NSString*)method params:(NSDictionary*)params {
  _url = [[self urlForMethod:method] retain];
  _method = [method copy];
  _params = params
    ? [[NSMutableDictionary alloc] initWithDictionary:params]
    : [[NSMutableDictionary alloc] init];

  [_params setObject:_method forKey:@"method"];
  [_params setObject:_session.apiKey forKey:@"api_key"];
  [_params setObject:kAPIVersion forKey:@"v"];
  [_params setObject:kAPIFormat forKey:@"format"];

  if (![self isSpecialMethod]) {
    [_params setObject:_session.sessionKey forKey:@"session_key"];
    [_params setObject:[self generateCallId] forKey:@"call_id"];

    if (_session.sessionSecret) {
      [_params setObject:@"1" forKey:@"ss"];
    }
  }
  
  [_params setObject:[self generateSig] forKey:@"sig"];
  
  [_session send:self];
}

- (void)post:(NSString*)url params:(NSDictionary*)params {
  _url = [url retain];
  _params = params
    ? [[NSMutableDictionary alloc] initWithDictionary:params]
    : [[NSMutableDictionary alloc] init];
  
  [_session send:self];
}

- (void)cancel {
  if (_connection) {
    [_connection cancel];
    [_connection release];
    _connection = nil;

    if ([_delegate respondsToSelector:@selector(requestWasCancelled:)]) {
      [_delegate requestWasCancelled:self];
    }
  }
}

@end
