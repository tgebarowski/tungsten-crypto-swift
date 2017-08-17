Pod::Spec.new do |s|
  s.name      = "TungstenCrypto"
  s.version   = "7.0.0"
  s.summary   = "TungstenCrypto"
  s.authors   = { "Tungsten Labs UG" => "https://tungstenapp.com/"}
  s.source    = { :git => "git@github.com:TungstenLabs/tungsten-crypto-swift.git", :tag => "#{s.version}" }
  s.homepage  = "https://github.com/TungstenLabs/tungsten-crypto-swift"
  s.license   = 'LICENSE*.*'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.9'

  s.source_files          = "TungstenCrypto/**/*.{h,m,swift}"

  s.ios.frameworks = 'Foundation', 'CoreFoundation'
  s.osx.frameworks = 'Foundation', 'CoreFoundation'

  s.dependency  'libCommonCrypto', '~> 0.1'
  s.dependency  'TungstenLibsodium', '~> 1.0.0'
  s.dependency  'ProtocolBuffers', '~> 1.9.8'
  s.dependency  'GRKOpenSSLFramework', '1.0.2.11.2'
    
  s.requires_arc = true
end
