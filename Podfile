platform :ios, '9.0'

inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'

def common_pods
    pod            'libCommonCrypto', '~> 0.1'
    pod            'TungstenLibsodium', '~> 1.0.0'
    pod            'ProtocolBuffers', '~> 1.9.8'
    pod            'GRKOpenSSLFramework', '1.0.2.11.2'
end

target 'TungstenCrypto' do
  use_frameworks!

  common_pods

  target 'TungstenCryptoTests' do
    inherit! :search_paths
    common_pods
  end

end
