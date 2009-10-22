//
//  WebTestAppAppDelegate.m
//  WebTestApp
//
//  Created by 藤川 宏之 on 09/10/21.
//  Copyright Hiroyuki-Fujikawa. 2009. All rights reserved.
//

#import "WebTestAppAppDelegate.h"

@implementation WebTestAppAppDelegate

@synthesize window;
@synthesize storedRequest;
@synthesize tagName;
@synthesize imageData;

- (void)dealloc {
    [window release];
	[thisWebView release];
	[storedRequest release];
	[tagName release];
	[imageData release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    // Override point for customization after application launch
    [window makeKeyAndVisible];
//	[self performSelector:@selector(loadHome) withObject:nil afterDelay:0.5f];
	[self loadHome];
}

- (IBAction)loadHome{
	NSLog(@"loadHome:%@", thisWebView);
	// 実験するうぷろだのURL
	NSURL *url = [NSURL URLWithString:@"http://www.google.com/"];
//	NSLog(@"url:%@", url);
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
//	NSLog(@"request:%@", request);
	[thisWebView loadRequest:request];
}

// 保存されたリクエストを実行する
- (IBAction)loadPage{
	if (self.storedRequest != nil) {
		// boundary検出
		NSString *boundary = @"boundary=nil";
		NSString *contentTypeStr = [self.storedRequest valueForHTTPHeaderField:@"Content-Type"];
		NSArray *tArray = [contentTypeStr componentsSeparatedByString:@"boundary="];
		if (tArray.count > 1) {
			boundary = [tArray objectAtIndex:1];
		}
		NSLog(@"boundary:%@", boundary);
		// HTTPBody分解、image埋め込み
		NSString *body = [[[NSString alloc] initWithData:self.storedRequest.HTTPBody encoding:NSASCIIStringEncoding] autorelease];
		NSArray *array = [body componentsSeparatedByString:boundary];
		NSRange range;
		NSMutableData *newBody = [[[NSMutableData alloc] init] autorelease];
		for (NSString *block in array) {
			NSLog(@"block:%@", block);
			range = [block rangeOfString:@"0xABADBABE"];
			if(range.location != NSNotFound){
				// <input type="file">
				// TODO: tagName複数化対応
				NSString *bodyHeader = [NSString stringWithFormat:@"%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"img.jpg\"\r\nContent-type: image/jpeg\r\n\r\n", boundary, tagName];
				[newBody appendData:[bodyHeader dataUsingEncoding:NSASCIIStringEncoding]];
				[newBody appendData:self.imageData];
				[newBody appendData:[@"--" dataUsingEncoding:NSASCIIStringEncoding]];
			}else {
				// 上記以外
				[newBody appendData:[boundary dataUsingEncoding:NSASCIIStringEncoding]];
				[newBody appendData:[block dataUsingEncoding:NSASCIIStringEncoding]];
			}
		}
		self.storedRequest.HTTPBody = newBody;
		[thisWebView loadRequest:self.storedRequest];
	}
}

#pragma mark UIWebViewDelegate
// ロード失敗
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	NSLog(@"didFailLoadWithError:%@", error);
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

// 読み込んで良いか？
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSLog(@"shouldStartLoadWithRequest:%@ navigationType:%d", request, navigationType);
//	NSLog(@"\tmethod-->%@", request.HTTPMethod);
//	NSLog(@"\theader-->%@", request.allHTTPHeaderFields);
	// 加工済みの場合はOK
	if ([[request valueForHTTPHeaderField:@"X-APP-ATTACH"] isEqualToString:@"yes"]) {
		return YES;
	}
	// POSTの時に処理をする
	switch (navigationType) {
		case UIWebViewNavigationTypeFormSubmitted:{	// FORMからの呼び出し
			NSString *contentTypeStr = [request valueForHTTPHeaderField:@"Content-Type"];
			NSLog(@"\tmethod-->%@", request.HTTPMethod);
			NSLog(@"\theader-->%@", request.allHTTPHeaderFields);
			NSLog(@"\theader(content type)-->%@", contentTypeStr);
			// bodyを分解する
			// > Content-Disposition: form-data; name="userfile[0]"
			// >
			// > 0xABADBABE
			// ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
			// > Content-disposition: attachment; filename="file.jpg"
			// > Content-type: image/jpeg
			// > Content-Transfer-Encoding: binary
			// >
			// > (DATA)
			NSLog(@"\tbody-->%@", [[[NSString alloc] initWithData:request.HTTPBody encoding:NSASCIIStringEncoding]autorelease]);
			if(!strcmp("NSMutableURLRequest", object_getClassName(request))){
				// 印をつけて保存する
				self.storedRequest = (NSMutableURLRequest*)request;
				[self.storedRequest setValue:@"yes" forHTTPHeaderField:@"X-APP-ATTACH"];
				UIImagePickerController *picker = [[UIImagePickerController alloc] init];
				picker.sourceType = UIImagePickerControllerSourceTypeCamera;
				picker.delegate = self;
				[self.window addSubview:picker.view];
				return NO;
			}
		}
		default:
			break;
	}
	return YES;
}

// ロード終了
- (void)webViewDidFinishLoad:(UIWebView *)webView {
//	NSLog(@"webViewDidFinishLoad");
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	// 細工をする
	NSString *ret = [webView stringByEvaluatingJavaScriptFromString:
					 @"function hf_input_replace(){"
					 @"var iTags = document.getElementsByTagName('input');"
					 @"var tagName = 0;"
					 @"for (var i= 0 ; i < iTags.length ; i++){"
					 @"if (iTags[i].type == 'file'){"
					 @"iTags[i].type='hidden';"
					 @"iTags[i].value='0xABADBABE';"
					 @"iTags[i].disabled=null;"
					 @"tagName = iTags[i].name;"
					 @"}"
					 @"}"
					 @"return tagName;"
					 @"};"
					 @"hf_input_replace();"
					 ];
	NSLog(@"<file>tag counter = %@", ret);
	self.tagName = ret;
}

// 読み込み開始した
- (void)webViewDidStartLoad:(UIWebView *)webView {
//	NSLog(@"webViewDidStartLoad:%@", webView.request);
	webView.scalesPageToFit = YES;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

#pragma mark UINavigationControllerDelegate

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSLog(@"didFinishPickingMediaWithInfo");
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	self.imageData = UIImageJPEGRepresentation(image, 0.9f);
	[picker.view removeFromSuperview];
	[self loadPage];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker.view removeFromSuperview];
}

@end
