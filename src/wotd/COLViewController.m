//
//  COLViewController.m
//  wotd
//
//  Created by Colin Milhench on 04/12/2013.
//  Copyright (c) 2013 Colin Milhench. All rights reserved.
//

#import "COLViewController.h"
#import "COLLocalJSURLProtocol.h"
#import "COLApiKey.h"

#define VIEWS 4
#define FOCUS 3

@interface COLViewController () {

}

@property (nonatomic, assign) int index;
@property (nonatomic, assign) int loaded;

@end

@implementation COLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"wotd" ofType:@"html" inDirectory:nil];
    NSString *htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    
    [NSURLProtocol registerClass:[COLLocalJSURLProtocol class]];
    
    int after = (VIEWS - FOCUS);
    int befor = (VIEWS - after - 1);
    
    self.scrollView.delegate = self;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * VIEWS, self.scrollView.frame.size.height);
    self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * befor, 0);
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    CGRect frame = CGRectMake(0.0f, 0.0f, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    for (int i = 0; i < VIEWS; i++)
    {
        frame.origin.x = self.scrollView.frame.size.width * i;
        UIWebView *webView = [[UIWebView alloc] initWithFrame:frame];
        webView.delegate = self;
        [webView loadHTMLString:htmlString baseURL:nil];
        [self.scrollView addSubview:webView];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -
#pragma mark UIWebViewDelegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    if ( navigationType == UIWebViewNavigationTypeLinkClicked )
    {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (++self.loaded != self.scrollView.subviews.count) { return; }
    int after = (VIEWS - FOCUS);
    int befor = (VIEWS - after - 1);
    for (int i = 0; i < self.scrollView.subviews.count; i++)
    {
        UIView *view = ((UIView *)(self.scrollView.subviews[i]));
        int offset = (i - befor);
        [self wordOfTheDayForWebView:(UIWebView*)(view) withOffset:self.index+offset];
    }
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int after = (VIEWS - FOCUS);
    int befor = (VIEWS - after - 1);
    int pos = (scrollView.contentOffset.x / scrollView.frame.size.width);
    CGRect frame = CGRectMake(0.0f, 0.0f, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    // -> next
    if(pos > (FOCUS - 1)) {
        ++self.index;
        if (self.index > 0) { self.index = 0; return; } // Only look backwards
        // Move each view left by <width> and wrap at length
        for (int i = 0; i < self.scrollView.subviews.count; i++)
        {
            UIView *view = ((UIView *)(self.scrollView.subviews[i]));
            frame.origin.x = view.frame.origin.x;
            frame.origin.x -= self.scrollView.frame.size.width;
            if (frame.origin.x < 0) {
                // wrap, i.e. move it to the end
                frame.origin.x = self.scrollView.frame.size.width * (VIEWS - 1);
                [self wordOfTheDayForWebView:(UIWebView*)view withOffset:self.index+after];
            }
            view.frame = frame;
        }
        [scrollView scrollRectToVisible: CGRectMake(self.scrollView.frame.size.width * befor, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height) animated:NO];
    }
    // <- prev
    if(pos < (FOCUS - 1)) {
        --self.index;
        // Move each view right by <width> and wrap at length
        for (int i = 0; i < self.scrollView.subviews.count; i++)
        {
            UIView *view = ((UIView *)(self.scrollView.subviews[i]));
            frame.origin.x = view.frame.origin.x;
            frame.origin.x += self.scrollView.frame.size.width;
            if (frame.origin.x >= self.scrollView.frame.size.width * VIEWS) {
                // wrap, i.e. move it to the start
                frame.origin.x = 0;
                [self wordOfTheDayForWebView:(UIWebView*)view withOffset:self.index-befor];
            }
            view.frame = frame;
        }
        [scrollView scrollRectToVisible: CGRectMake(self.scrollView.frame.size.width * befor, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height) animated:NO];
    }
}

#pragma mark -
#pragma mark Private Methods

- (void) wordOfTheDayForWebView:(UIWebView *)webView withOffset:(NSInteger)offset
{
    NSString *apiEnd = @"wordOfTheDay";
    //NSString *apiEnd = @"randomWord";
    NSString *apiKey = APIKEY;
    NSString *apiURL = @"http://api.wordnik.com/v4/words.json/";    NSString *apiDate = [self dateStringFromOffset:offset];
    
    apiURL = [NSString stringWithFormat:@"%@%@?api_key=%@&date=%@", apiURL, apiEnd, apiKey, apiDate];
    
    NSURL *url = [NSURL URLWithString:apiURL];
    
    //NSLog(@"loading %@ for %@", apiEnd, apiDate);
    NSString *javaScript = [NSString stringWithFormat:@"loading({ date:'%@' });", apiDate];
    [webView stringByEvaluatingJavaScriptFromString:javaScript];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Do background work here
        NSError *error;
        NSString *jsonString = [NSString stringWithContentsOfURL:url encoding: NSUTF8StringEncoding error:&error];
        NSString *jsonErr = @"null";
        if (error) {
            jsonErr = [NSString stringWithFormat:@"'%@'", [error localizedDescription]];
            jsonString = @"{}";
        }
        //[NSThread sleepForTimeInterval:1.0f];
        dispatch_async( dispatch_get_main_queue(), ^{
            // Back on the IU thread
            NSString *jsonData = [NSString stringWithFormat:@"{ date:'%@', data: %@ }", apiDate, jsonString];
            NSString *javaScript = [NSString stringWithFormat:@"%@(%@, %@);", apiEnd, jsonErr, jsonData];
            //NSLog(@"sending %@", javaScript);
            [webView stringByEvaluatingJavaScriptFromString:javaScript];
        });
    });
}

- (NSString *) dateStringFromOffset:(NSInteger)offset
{
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow: (60.0f*60.0f*24.0f*offset)];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    
    return [formatter stringFromDate:date];
}

@end
