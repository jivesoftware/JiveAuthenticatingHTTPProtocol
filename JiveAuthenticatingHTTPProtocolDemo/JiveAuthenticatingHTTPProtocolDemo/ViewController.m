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

@end

@implementation ViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [JAHPAuthenticatingHTTPProtocol setDelegate:self];
    [JAHPAuthenticatingHTTPProtocol start];
    self.webView.delegate = self;
    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://httpbin.org/basic-auth/foo/bar"]]];
}

#pragma mark - JAHPAuthenticatingHTTPProtocolDelegate

- (BOOL)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    BOOL canAuthenticate = [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic];
    return canAuthenticate;
}

- (void)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    self.authenticatingHTTPProtocol = authenticatingHTTPProtocol;
    
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

- (void)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol logWithFormat:(NSString *)format arguments:(va_list)arguments {
    NSLog(@"%@", [[NSString alloc] initWithFormat:format arguments:arguments]);
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
    [self.authenticatingHTTPProtocol resolvePendingAuthenticationChallengeWithCredential:credential];
    self.authenticatingHTTPProtocol = nil;
}

@end
