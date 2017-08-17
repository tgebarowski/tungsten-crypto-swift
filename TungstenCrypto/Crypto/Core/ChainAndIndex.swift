//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class ChainAndIndex: NSObject {
    private(set) public var chain: Chain
    private(set) public var index: Int
    
    public init(chain: Chain, index: Int) {
        self.chain = chain
        self.index = index
    }
}
