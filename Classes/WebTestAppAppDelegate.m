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
@synthesize tagNames;
@synthesize imageDatas;

- (void)dealloc {
    [window release];
	[thisWebView release];
	[storedRequest release];
	[tagNames release];
	[imageDatas release];
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

// 一時メソッド：写真を取得する
- (void)openPicker {
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		picker.sourceType = UIImagePickerControllerSourceTypeCamera;
	}
	picker.delegate = self;
	[self.window addSubview:picker.view];
}

// 一時メソッド：要素名が写真を扱うものか？
- (BOOL)isFilePart:(NSString *)str {
	// ↓の状態を判定 (?????はself.tagName配列に入っている)
	// Content-Disposition: form-data; name="?????"
	// 
	// 0xABADBABE
	
	NSRange range = [str rangeOfString:@"0xABADBABE"];
	if(range.location != NSNotFound){
		NSLog(@"key string detect:%d", self.tagNames.count);
		for (NSString *name in self.tagNames) {
			NSLog(@"tag:%@", name);
			range = [str rangeOfString:name];
			if(range.location != NSNotFound){
				return YES;
			}
		}
	}
	NSLog(@"not FilePart");
	return NO;
}

// 一時メソッド：ファイル用ヘッダを返す
- (NSString*)fileHeader:(NSString*)str withNum:(int)num {
	// Content-Disposition: form-data; name="photo1"
	// ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
	// Content-Disposition: form-data; name="photo1"; filename="file.jpg"
	// Content-type: image/jpeg
	// Content-Transfer-Encoding: binary
	NSArray *lineArray = [str componentsSeparatedByString:@"\r\n"];
	NSLog(@"lineArray:%@", lineArray);
	return [[[NSMutableString alloc] initWithFormat:@"%@; filename=\"file%d.jpg\"\r\nContent-type: image/jpeg\r\n", [lineArray objectAtIndex:1], num] autorelease];
	// return [[[NSMutableString alloc] initWithFormat:@"%@; filename=\"file.jpg\"\r\nContent-type: image/jpeg\r\nContent-Transfer-Encoding: binary\r\n", [lineArray objectAtIndex:0]] autorelease];
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
		// > Content-Disposition: form-data; name="userfile[0]"
		// >
		// > 0xABADBABE
		// ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
		// > Content-disposition: attachment; filename="file.jpg"
		// > Content-type: image/jpeg
		// > Content-Transfer-Encoding: binary
		// >
		// > (DATA)
		NSString *body = [[[NSString alloc] initWithData:self.storedRequest.HTTPBody encoding:NSNEXTSTEPStringEncoding] autorelease];
		NSArray *array = [body componentsSeparatedByString:boundary];
		NSMutableData *newBody = [[[NSMutableData alloc] init] autorelease];
		int imageNum = 0;
		for (NSString *block in array) {
			NSLog(@"block:%@", block);
			// ファイルを示すmime partか？
			// if((imageNum < self.imageDatas.count) && [self isFilePart:block]){
			if([self isFilePart:block]){
				// <input type="file">
				// TODO: tagName複数化対応
				if(imageNum < self.imageDatas.count){
					NSLog(@"putImage");
					NSString *bodyHeader = [NSString stringWithFormat:@"%@\r\n%@\r\n", boundary, [self fileHeader:block withNum:imageNum]];
					[newBody appendData:[bodyHeader dataUsingEncoding:NSNEXTSTEPStringEncoding]];
					[newBody appendData:[self.imageDatas objectAtIndex:imageNum]];
					[newBody appendData:[@"\r\n--" dataUsingEncoding:NSNEXTSTEPStringEncoding]];
					imageNum ++;
				}else {
					NSLog(@"no image");
					NSArray *lineArray = [block componentsSeparatedByString:@"\r\n"];
					NSString *bodyHeader = [NSString stringWithFormat:@"%@\r\n%@\r\n\r\n--", boundary, [lineArray objectAtIndex:0]];
					[newBody appendData:[bodyHeader dataUsingEncoding:NSNEXTSTEPStringEncoding]];
				}
			}else {
				// 上記以外
				[newBody appendData:[boundary dataUsingEncoding:NSNEXTSTEPStringEncoding]];
				[newBody appendData:[block dataUsingEncoding:NSNEXTSTEPStringEncoding]];
			}
		}
		self.tagNames = nil;
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
	NSLog(@"\tmethod-->%@", request.HTTPMethod);
	NSLog(@"\theader-->%@", request.allHTTPHeaderFields);
	// 加工済みの場合はOK
	if ([[request valueForHTTPHeaderField:@"X-APP-ATTACH"] isEqualToString:@"yes"]) {
		return YES;
	}
	// POSTの時に処理をする
	if ([request.HTTPMethod isEqualToString:@"POST"]) {
		if (self.tagNames != nil) {
			NSString *contentTypeStr = [request valueForHTTPHeaderField:@"Content-Type"];
			NSLog(@"\tmethod-->%@", request.HTTPMethod);
			NSLog(@"\theader-->%@", request.allHTTPHeaderFields);
			NSLog(@"\theader(content type)-->%@", contentTypeStr);
			NSLog(@"\tbody-->%@", [[[NSString alloc] initWithData:request.HTTPBody encoding:NSNEXTSTEPStringEncoding]autorelease]);
			if(!strcmp("NSMutableURLRequest", object_getClassName(request))){
				// 印をつけて保存する
				self.storedRequest = (NSMutableURLRequest*)request;
				[self.storedRequest setValue:@"yes" forHTTPHeaderField:@"X-APP-ATTACH"];
				// 写真データを取得する
				self.imageDatas = [[[NSMutableArray alloc] init] autorelease];
				[self openPicker];
				return NO;
			}
		}else {
			NSLog(@"no file tag:%@", self.tagNames);
		}

	}
	return YES;
}

// ロード終了
- (void)webViewDidFinishLoad:(UIWebView *)webView {
//	NSLog(@"webViewDidFinishLoad");
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	// NSLog(@"HTML:%@", [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"]);
	// 細工をする
	NSString *ret = [webView stringByEvaluatingJavaScriptFromString:
					 @"function hf_input_replace(){"
					 @"var iTags = document.getElementsByTagName('input');"
					 @"var tagName = 0;"
					 @"for (var i= 0 ; i < iTags.length ; i++){"
					 @"if (iTags[i].type == 'file'){"
					 @"tagName = tagName + \"\\\"\" + iTags[i].name;"
					 @"var newNode = document.createElement('div');"
					 @"var newInput = document.createElement('input');"
					 @"var textNode = document.createTextNode('「送信時に写真を撮影します」');"
					 @"newInput.name = iTags[i].name;"
					 @"newInput.type = 'hidden';"
					 @"newInput.value = '0xABADBABE';"
					 @"newNode.appendChild(newInput);"
					 @"newNode.appendChild(textNode);"
					 @"iTags[i].parentNode.replaceChild(newNode, iTags[i]);"
					 @"newNode.appendChild(iTags[i]);"
					 @"}"
					 @"}"
					 @"return tagName;"
					 @"};"
					 @"hf_input_replace();"
					 ];
	if(![ret isEqualToString:@"0"]){
		self.tagNames = [ret componentsSeparatedByString:@"\""];
		NSLog(@"<file>tag counter = %d %@", self.tagNames.count, self.tagNames);
	}
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
	NSLog(@"didFinishPickingMediaWithInfo:%d", self.imageDatas.count);
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	[self.imageDatas addObject:UIImageJPEGRepresentation(image, 0.9f)];
	[picker.view removeFromSuperview];
	NSLog(@"didFinishPickingMediaWithInfo:%d / %d", self.imageDatas.count, self.tagNames.count);
	if ((self.imageDatas.count + 1) < self.tagNames.count) {
		[self openPicker];
		return;
	}
	[self loadPage];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	NSLog(@"imagePickerControllerDidCancel:%d", self.imageDatas.count);
	[picker.view removeFromSuperview];
	if (self.imageDatas.count > 0) {
		[self loadPage];
	}
}

@end
