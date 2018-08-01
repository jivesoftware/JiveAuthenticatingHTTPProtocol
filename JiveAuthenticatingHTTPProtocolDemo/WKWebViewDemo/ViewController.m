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

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, strong) UIAlertView *authAlertView;
@property (nonatomic, copy) WKWebViewAuthChallengeBlock webViewChallengeBlock;

@property (nonatomic, strong) NSURLCredential* userInput;
@property (nonatomic, assign) BOOL isUserInputAcceptedByServer;

@end

@implementation ViewController

#pragma mark - UIViewController

-(BOOL)isUserInputCredentialsMemoized {
    
    BOOL hasInput = (nil != self.userInput);
    BOOL result = hasInput && self.isUserInputAcceptedByServer;
    
    return result;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // The pre-built credentialas to skip the dialog
    // Might be useful for web page content debugging
    //
    //    NSURLCredential *credential = [NSURLCredential credentialWithUser: @"foo"
    //                                                             password: @"bar"
    //                                                          persistence: NSURLCredentialPersistenceNone];
    //    self.userInput = credential;
    
    
    // https://github.com/cyyuen/ADCookieIsolatedWebView
    // https://github.com/jjconti/swift-webview-isolated
    //
    //
    
    WKWebViewConfiguration* config = [WKWebViewConfiguration new];
    config.allowsInlineMediaPlayback = YES;
    config.allowsPictureInPictureMediaPlayback = NO;
    config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
    config.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    
    CGRect fullScreen = self.view.bounds;
    WKWebView* webView = [[WKWebView alloc] initWithFrame: fullScreen
                                            configuration: config];
    self.webView = webView;
    
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview: webView];
    
    [NSLayoutConstraint activateConstraints:
    @[
     [webView.topAnchor    constraintEqualToAnchor: self.topLayoutGuide.bottomAnchor],
     [webView.bottomAnchor constraintEqualToAnchor: self.bottomLayoutGuide.topAnchor],
     [webView.leftAnchor   constraintEqualToAnchor: self.view.leftAnchor            ],
     [webView.rightAnchor  constraintEqualToAnchor: self.view.rightAnchor           ]
    ]];
    

    self.webView.navigationDelegate = self;
        
    NSString* txtUrl = @"https://httpbin.org/basic-auth/foo/bar";
    NSURL* url = [NSURL URLWithString: txtUrl];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL: url];
    [self.webView loadRequest: request];
}

#pragma mark - JAHPAuthenticatingHTTPProtocolDelegate
- (BOOL)shouldShowDialogForAuthorizationMethod:(NSString*)authorizationMethod
{
    NSLog(@"shouldShowDialogForAuthorizationMethod: %@", authorizationMethod);
    
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

#pragma mark - WKWebViewDelegate - logic
-(void)webView:(WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(WKWebViewAuthChallengeBlock)completionHandler
{
    NSString* authMethod = [[challenge protectionSpace] authenticationMethod];
    BOOL shouldIntercept = [self shouldShowDialogForAuthorizationMethod: authMethod];
 
    NSLog(@"webView:didReceiveAuthenticationChallenge: %@ | %@ | %@"
          , [challenge debugDescription]
          , [challenge protectionSpace]
          , authMethod);
    
    if (!shouldIntercept)
    {
        NSLog(@"webView:didReceiveAuthenticationChallenge: not intercepting - %@", authMethod);
        
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }
    
    if ([self isUserInputCredentialsMemoized])
    {
        NSLog(@"webView:didReceiveAuthenticationChallenge: has memoized credentials - %@", [self.userInput debugDescription]);
        
        completionHandler(NSURLSessionAuthChallengeUseCredential, self.userInput);
        return;
    }
    
    //=== show alert
    //
    NSLog(@"webView:didReceiveAuthenticationChallenge: need credentials. Showing the dialog");
    
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

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    NSLog(@"webView:decidePolicyForNavigationResponse: %@", [navigationResponse debugDescription]);
    
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSLog(@"webView:decidePolicyForNavigationAction: %@", [navigationAction debugDescription]);
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKWebViewDelegate - traces
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    NSLog(@"webViewWebContentProcessDidTerminate:");
}

- (void)webView:(WKWebView *)webView
didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    NSLog(@"webView:didFinishNavigation: %@", [navigation debugDescription]);
    
    // The page has been loaded.
    //
    // When we have the credentials input,
    // it might be correct to assume...
    // that it was the request we were asking the credentials for.
    //
    // Marking the credentials as "correct" to avoid "alert spam"
    // Otherwise the alerts will be popping up until cancelled
    //
    if (nil != self.userInput)
    {
        self.isUserInputAcceptedByServer = YES;
    }
}

- (void)webView:(WKWebView *)webView
didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
    NSLog(@"webView:didCommitNavigation: %@", [navigation debugDescription]);
}

- (void)webView:(WKWebView *)webView
didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation
      withError:(NSError *)error
{
    NSLog(@"webView:didFailProvisionalNavigation: %@", [navigation debugDescription]);
    
    [[[UIAlertView alloc] initWithTitle:@"JAHPDemo"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)webView:(WKWebView *)webView
didFailNavigation:(null_unspecified WKNavigation *)navigation
      withError:(NSError *)error
{
    NSLog(@"webView:didFailNavigation: %@", [navigation debugDescription]);
    
    [[[UIAlertView alloc] initWithTitle:@"JAHPDemo"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

#pragma mark - WKWebViewDelegate - trace Provisioning navigation

- (void)webView:(WKWebView *)webView
didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    NSLog(@"webView:didReceiveServerRedirectForProvisionalNavigation: %@", [navigation debugDescription]);
}

- (void)webView:(WKWebView *)webView
didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    NSLog(@"webView:didReceiveServerRedirectForProvisionalNavigation: %@", [navigation debugDescription]);
}

#pragma mark - Private API

- (void)cancelChallengeAfterAlertViewDismissal
{
    NSLog(@"cancelChallengeAfterAlertViewDismissal");
    
    if (nil != self.webViewChallengeBlock)
    {
        self.webViewChallengeBlock(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
    
    self.authAlertView = nil;
}

- (void)useAuthAlertViewUsernamePasswordForChallenge {
    
    NSLog(@"useAuthAlertViewUsernamePasswordForChallenge");
    
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
    
    NSLog(@"passCredentialsInputToConnection");
    
    NSParameterAssert(nil != self.userInput);
    NSParameterAssert(nil != self.webViewChallengeBlock);
    
    self.webViewChallengeBlock(NSURLSessionAuthChallengeUseCredential, self.userInput);
}

@end
