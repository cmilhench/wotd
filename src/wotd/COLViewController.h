//
//  COLViewController.h
//  wotd
//
//  Created by Colin Milhench on 04/12/2013.
//  Copyright (c) 2013 Colin Milhench. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface COLViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end
