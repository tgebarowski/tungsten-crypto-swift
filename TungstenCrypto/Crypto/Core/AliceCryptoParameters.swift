//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class AliceCryptoParameters: NSObject, CryptoParameters {

    private(set) public var ourBaseKey: KeyPair
    private(set) public var theirSignedInitKey: Data
    private(set) public var theirCoreKey: Data
    private(set) public var theirOneTimeInitKey: Data?

    private(set) public var ourIdentityKeyPair: KeyPair
    private(set) public var theirIdentityKey: Data
    
    public init(identityKey: KeyPair,
         theirIdentityKey: Data,
         ourBaseKey: KeyPair,
         theirSignedInitKey: Data,
         theirOneTimeInitKey: Data?,
         theirCoreKey: Data) {
        
        self.ourIdentityKeyPair = identityKey
        self.theirIdentityKey = theirIdentityKey
        self.ourBaseKey = ourBaseKey
        self.theirSignedInitKey = theirSignedInitKey
        self.theirOneTimeInitKey = theirOneTimeInitKey
        self.theirCoreKey = theirCoreKey
    }
}
