//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class RKCK: NSObject {
    
    private(set) public var rootKey: RootKey
    private(set) public var chainKey: ChainKey
    
    public init(rootKey: RootKey, chainKey: ChainKey) {
        self.rootKey = rootKey
        self.chainKey = chainKey
    }
}
