JiveAuthenticatingHTTPProtocol
=======================

Based on [Apple's CustomHTTPProtocol](https://developer.apple.com/library/prerelease/ios/samplecode/CustomHTTPProtocol/Introduction/Intro.html),
`JiveAuthenticatingHTTPProtocol` provides authentication callbacks for a `UIWebView`.

Usage
-----
`JiveAuthenticatingHTTPProtocol` captures all `NSURLConnection` traffic. Ensure that no other `NSURLConnection`s can start after you call `+[JAHPAuthenticatingHTTPProtocol start]`. Before loading an `NSURLRequest` that may require handling an authentication callback, call `+[JAHPAuthenticatingHTTPProtocol setDelegate:]`, then `+[JAHPAuthenticatingHTTPProtocol start]`. Finally, load your `NSURLRequest`, and handle the callbacks from `JAHPAuthenticatingHTTPProtocolDelegate`.

See JiveAuthenticatingHTTPProtocolDemo/ViewController.m for an example.

License
-------

BSD per the LICENSE file.

