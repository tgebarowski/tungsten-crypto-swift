//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class CryptoPublicInitKey: NSObject {
    
    private(set) public var identifier: Int
    private(set) public var publicKey: Data
    
    public init(identifier: Int, publicKey: Data) {
        self.identifier = identifier
        self.publicKey = publicKey
    }
}
