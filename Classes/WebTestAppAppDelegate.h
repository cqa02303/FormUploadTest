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
	NSString *tagName;
	NSData *imageData;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) NSMutableURLRequest *storedRequest;
@property (nonatomic, retain) NSString *tagName;
@property (nonatomic, retain) NSData *imageData;

- (IBAction)loadHome;
- (IBAction)loadPage;

@end

