//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class BobCryptoParameters: NSObject, CryptoParameters {
    
    private(set) public var ourSignedInitKey: KeyPair
    private(set) public var ourCoreKey: KeyPair
    private(set) public var ourOneTimeInitKey: KeyPair?
    private(set) public var theirBaseKey: Data
    
    private(set) public var ourIdentityKeyPair: KeyPair
    private(set) public var theirIdentityKey: Data
    
    public init(identityKey: KeyPair,
         theirIdentityKey: Data,
         ourSignedInitKey: KeyPair,
         ourCoreKey: KeyPair,
         ourOneTimeInitKey: KeyPair?,
         theirBaseKey: Data) {
        self.ourIdentityKeyPair = identityKey
        self.theirIdentityKey = theirIdentityKey
        self.ourSignedInitKey = ourSignedInitKey
        self.ourCoreKey = ourCoreKey
        self.ourOneTimeInitKey = ourOneTimeInitKey
        self.theirBaseKey = theirBaseKey
    }
}
