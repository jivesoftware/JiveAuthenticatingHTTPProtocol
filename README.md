JiveAuthenticatingHTTPProtocol
=======================

Based on [Apple's CustomHTTPProtocol](https://developer.apple.com/library/prerelease/ios/samplecode/CustomHTTPProtocol/Introduction/Intro.html),
`JiveAuthenticatingHTTPProtocol` provides authentication callbacks for a `UIWebView`.

#### Note :

```
No cleanup of the sample code has been done, so there might be some strange "patterns" inside. 
```

See https://github.com/jivesoftware/JiveAuthenticatingHTTPProtocol/issues/3 for more details.


Usage
-----
`JiveAuthenticatingHTTPProtocol` captures all `NSURLConnection` traffic. 

1. Ensure that no other `NSURLConnection`s can start after you call `+[JAHPAuthenticatingHTTPProtocol start]`. 
2. Before loading an `NSURLRequest` that may require handling an authentication callback, call `+[JAHPAuthenticatingHTTPProtocol setDelegate:]`, 
3. Then call `+[JAHPAuthenticatingHTTPProtocol start]`. 
4. Finally, load your `NSURLRequest`, and handle the callbacks from `JAHPAuthenticatingHTTPProtocolDelegate`.

See `JiveAuthenticatingHTTPProtocolDemo/ViewController.m` for an example.

It might be a good idea to memoize the credentials entered by the user to avoid "spamming" them with the data input alerts. This is an absolute "must" if your page contains the video which requires authorization.



Supported Authorization Methods
-----
This library supports all of the authentication schemes `NSURLAuthentication` supports.

This has been tested with `NTLM` and `ADFS` authentication, (which `NSURLAuthentication` natively supports). Basically, if an authentication method works in `Safari`, it'll probably work here, too.

You can add more authorization methods like this :

```obj-c
- (BOOL)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    NSArray* interceptedAuthMethods =
    @[
      NSURLAuthenticationMethodHTTPBasic
      , NSURLAuthenticationMethodNTLM
    ];
    
    NSSet* interceptedAuthMethodsSet = [NSSet setWithArray: interceptedAuthMethods];
    
    BOOL canAuthenticate =
        [interceptedAuthMethodsSet containsObject: protectionSpace.authenticationMethod];
    
    return canAuthenticate;
}
```


#### Caution : 

```
Stubbing the above function to always return "true" is not always a good idea.
If you do so, it would be your responsibility to implement all the required handshakes.
```



License
-------

BSD per the LICENSE file.

