//
//  WebTestAppAppDelegate.h
//  WebTestApp
//
//  Created by 藤川 宏之 on 09/10/21.
//  Copyright Hiroyuki-Fujikawa. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebTestAppAppDelegate : NSObject <UIApplicationDelegate, UIWebViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    UIWindow *window;
	IBOutlet UIWebView *thisWebView;
	NSMutableURLRequest *storedRequest;
	NSArray *tagNames;
	NSMutableArray *imageDatas;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) NSMutableURLRequest *storedRequest;
@property (nonatomic, retain) NSArray *tagNames;
@property (nonatomic, retain) NSMutableArray *imageDatas;

- (IBAction)loadHome;
- (IBAction)loadPage;

@end

