//
//  ViewController.m
//  JiveAuthenticatingHTTPProtocolDemo
//
//  Created by Heath Borders on 3/26/15.
//  Copyright (c) 2015 Jive Software. All rights reserved.
//

#import "ViewController.h"

#import <WebKit/WebKit.h>

typedef void (^WKWebViewAuthChallengeBlock)(
    NSURLSessionAuthChallengeDisposition,
    NSURLCredential * _Nullable);

@interface ViewController ()
<
  UIAlertViewDelegate
, WKNavigationDelegate
>

@property (nonatomic, weak) IBOutlet WKWebView *webView;
@property (nonatomic, strong) UIAlertView *authAlertView;
@property (nonatomic, copy) WKWebViewAuthChallengeBlock webViewChallengeBlock;

@property (nonatomic, strong) NSURLCredential* userInput;

@end

@implementation ViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView.navigationDelegate = self;
    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://httpbin.org/basic-auth/foo/bar"]]];
}

#pragma mark - JAHPAuthenticatingHTTPProtocolDelegate
- (BOOL)shouldShowDialogForAuthorizationMethod:(NSString*)authorizationMethod
{
    NSArray* interceptedAuthMethods =
    @[
        NSURLAuthenticationMethodHTTPBasic
      , NSURLAuthenticationMethodHTTPDigest
      , NSURLAuthenticationMethodNTLM
    ];
    
    NSSet* interceptedAuthMethodsSet = [NSSet setWithArray: interceptedAuthMethods];
    
    BOOL canAuthenticate =
        [interceptedAuthMethodsSet containsObject: authorizationMethod];
    
    return canAuthenticate;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == self.authAlertView.cancelButtonIndex) {
        [self cancelChallengeAfterAlertViewDismissal];
    } else if (buttonIndex == self.authAlertView.firstOtherButtonIndex) {
        [self useAuthAlertViewUsernamePasswordForChallenge];
    }
}

- (void)alertViewCancel:(UIAlertView *)alertView {
    [self cancelChallengeAfterAlertViewDismissal];
}

#pragma mark - WKWebViewDelegate
-(void)webView:(WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(WKWebViewAuthChallengeBlock)completionHandler
{
    NSString* authMethod = [[challenge protectionSpace] authenticationMethod];
    BOOL shouldIntercept = [self shouldShowDialogForAuthorizationMethod: authMethod];
    
    if (!shouldIntercept)
    {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }
    
    if (nil != self.userInput)
    {
        completionHandler(NSURLSessionAuthChallengeUseCredential, self.userInput);
        return;
    }
    
    //=== show alert
    //
    self.webViewChallengeBlock = completionHandler;
    
    self.authAlertView = [[UIAlertView alloc] initWithTitle:@"JAHPDemo"
                                                    message:@"Enter 'foo' for the username and 'bar' for the password"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:
                          @"OK",
                          nil];
    self.authAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [self.authAlertView show];
}


#pragma mark - Private API

- (void)cancelChallengeAfterAlertViewDismissal
{
    if (nil != self.webViewChallengeBlock)
    {
        self.webViewChallengeBlock(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
    
    self.authAlertView = nil;
}

- (void)useAuthAlertViewUsernamePasswordForChallenge {
    NSString *username = [self.authAlertView textFieldAtIndex:0].text;
    NSString *password = [self.authAlertView textFieldAtIndex:1].text;
    self.authAlertView = nil;
    NSURLCredential *credential = [NSURLCredential credentialWithUser:username
                                                             password:password
                                                          persistence:NSURLCredentialPersistenceNone];
    self.userInput = credential;
    
    
    [self passCredentialsInputToConnection];
}

-(void)passCredentialsInputToConnection {
    
    NSParameterAssert(nil != self.userInput);
    NSParameterAssert(nil != self.webViewChallengeBlock);
    
    self.webViewChallengeBlock(NSURLSessionAuthChallengeUseCredential, self.userInput);
}

@end
