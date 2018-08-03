//
//  ViewController.m
//  JiveAuthenticatingHTTPProtocolDemo
//
//  Created by Heath Borders on 3/26/15.
//  Copyright (c) 2015 Jive Software. All rights reserved.
//

#import "ViewController.h"
#import <JiveAuthenticatingHTTPProtocol/JAHPAuthenticatingHTTPProtocol.h>

@interface ViewController () <JAHPAuthenticatingHTTPProtocolDelegate, UIAlertViewDelegate, UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@property (nonatomic, strong) UIAlertView *authAlertView;
@property (nonatomic, strong) JAHPAuthenticatingHTTPProtocol *authenticatingHTTPProtocol;

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
    
    [JAHPAuthenticatingHTTPProtocol setDelegate:self];
    [JAHPAuthenticatingHTTPProtocol start];
    
    
    self.webView.delegate = self;
    
    NSString* txtUrl = @"https://httpbin.org/basic-auth/foo/bar";
    NSURL* url = [NSURL URLWithString: txtUrl];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL: url];
    [self.webView loadRequest: request];
}

#pragma mark - JAHPAuthenticatingHTTPProtocolDelegate

- (BOOL)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {

    NSArray* interceptedAuthMethods =
    @[
        NSURLAuthenticationMethodHTTPBasic
      , NSURLAuthenticationMethodHTTPDigest
      , NSURLAuthenticationMethodNTLM
    ];
    
    NSSet* interceptedAuthMethodsSet = [NSSet setWithArray: interceptedAuthMethods];
    
    BOOL canAuthenticate =
    [interceptedAuthMethodsSet containsObject: protectionSpace.authenticationMethod];
    
    return canAuthenticate;
}


#define USE_PROTOCOL_FOR_CANCELLATION 0
#if USE_PROTOCOL_FOR_CANCELLATION
- (JAHPDidCancelAuthenticationChallengeHandler)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    self.authenticatingHTTPProtocol = authenticatingHTTPProtocol;
    
    if ([self isUserInputCredentialsMemoized]) {
        
        [self passCredentialsInputToConnection];
        return;
    }
    
    
    self.authAlertView = [[UIAlertView alloc] initWithTitle:@"JAHPDemo"
                                                    message:@"Enter 'foo' for the username and 'bar' for the password"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:
                          @"OK",
                          nil];
    self.authAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [self.authAlertView show];
    return nil;
}

- (void)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self.authAlertView dismissWithClickedButtonIndex:self.authAlertView.cancelButtonIndex
                                             animated:YES];
    self.authAlertView = nil;
    self.authenticatingHTTPProtocol = nil;
    
    [[[UIAlertView alloc] initWithTitle:@"JAHPDemo"
                                message:@"The URL Loading System cancelled authentication"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}
#else
- (JAHPDidCancelAuthenticationChallengeHandler)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    __weak ViewController* weakSelf = self;
    self.authenticatingHTTPProtocol = authenticatingHTTPProtocol;
    
    
    JAHPDidCancelAuthenticationChallengeHandler result =
    ^(JAHPAuthenticatingHTTPProtocol *authenticatingHTTPProtocol, NSURLAuthenticationChallenge *challenge) {
        ViewController* strongSelf = weakSelf;
        
        [strongSelf.authAlertView dismissWithClickedButtonIndex:strongSelf.authAlertView.cancelButtonIndex
                                                 animated:YES];
        strongSelf.authAlertView = nil;
        strongSelf.authenticatingHTTPProtocol = nil;
        
        [[[UIAlertView alloc] initWithTitle:@"JAHPDemo"
                                    message:@"The URL Loading System cancelled authentication"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    };
    
    
    
    if ([self isUserInputCredentialsMemoized]) {
        
        [self passCredentialsInputToConnection];
        return result;
    }
    
    self.authAlertView = [[UIAlertView alloc] initWithTitle:@"JAHPDemo"
                                                    message:@"Enter 'foo' for the username and 'bar' for the password"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:
                          @"OK",
                          nil];
    self.authAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [self.authAlertView show];
    
    return result;
}
#endif


// It's ok to not overload this method.
// Then all logs will go to the `authenticatingHTTPProtocol:logMessage:` method
//
//- (void)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol logWithFormat:(NSString *)format arguments:(va_list)arguments {
//
//    NSLog(@"logWithFormat: %@", [[NSString alloc] initWithFormat:format arguments:arguments]);
//}

- (void)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol logMessage:(NSString *)message {
    NSLog(@"logMessage: %@", message);
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

#pragma mark - UIWebViewDelegate

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    
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

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"JAHPDemo"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

#pragma mark - Private API

- (void)cancelChallengeAfterAlertViewDismissal {
    [self.authenticatingHTTPProtocol cancelPendingAuthenticationChallenge];
    self.authenticatingHTTPProtocol = nil;
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
    NSParameterAssert(nil != self.authenticatingHTTPProtocol);
    
    [self.authenticatingHTTPProtocol resolvePendingAuthenticationChallengeWithCredential:self.userInput];
    self.authenticatingHTTPProtocol = nil;
}

@end
