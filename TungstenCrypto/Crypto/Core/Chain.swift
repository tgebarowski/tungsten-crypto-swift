//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

@objc public protocol Chain: NSObjectProtocol, NSSecureCoding {
    var chainKey: ChainKey { get set }
}


