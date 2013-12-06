//
//  COLLocalJSURLProtocol.m
//  wotd
//
//  Created by Colin Milhench on 04/12/2013.
//  Copyright (c) 2013 Colin Milhench. All rights reserved.
//

#import "COLLocalJSURLProtocol.h"

@implementation COLLocalJSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return [request.URL.scheme caseInsensitiveCompare:@"applewebdata"] == NSOrderedSame &&
        ([request.URL.lastPathComponent hasSuffix:@"js"]
         || [request.URL.lastPathComponent hasSuffix:@"css"]
         || [request.URL.lastPathComponent hasSuffix:@"png"]);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSURLRequest *request = self.request;
    
    NSString *filePath = [request.URL.path stringByDeletingPathExtension];
    NSString *fileType = [[[[request URL] absoluteURL] path] pathExtension];
    NSString *mimeType = @"text/javascript";
    
    if ([fileType isEqualToString:@"css"]) {
        mimeType = @"text/css";
    } else if ([fileType isEqualToString:@"png"]){
        mimeType = @"image/png";
    }
    
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[request URL]
                                                        MIMEType:mimeType
                                           expectedContentLength:-1
                                                textEncodingName:nil];
    
    NSString *localFilePath = [[NSBundle mainBundle] pathForResource:filePath ofType:fileType inDirectory:nil];
    NSData *data = [NSData dataWithContentsOfFile:localFilePath];
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
    
}

- (void)stopLoading
{
}

@end
