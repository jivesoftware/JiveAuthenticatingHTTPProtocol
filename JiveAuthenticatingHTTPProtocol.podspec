Pod::Spec.new do |s|
  s.name = 'JiveAuthenticatingHTTPProtocol'
  s.version = '0.1.0'
  s.license = { :type => 'BSD', :file => 'LICENSE' }
  s.summary = 'JiveAuthenticatingHTTPProtocol provides authentication callbacks for a UIWebView'
  s.homepage = 'https://github.com/jivesoftware/JiveAuthenticatingHTTPProtocol'
  s.social_media_url = 'http://twitter.com/JiveSoftware'
  s.authors = { 'Jive Mobile' => 'jive-mobile@jivesoftware.com' }
  s.source = { :git => 'https://github.com/jivesoftware/JiveAuthenticatingHTTPProtocol.git', :tag => s.version }

  s.ios.deployment_target = '7.0'

  s.requires_arc = true
  s.source_files = 'Source/JiveAuthenticatingHTTPProtocol/*.{h,m}'

end
