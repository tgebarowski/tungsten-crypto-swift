//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class SecretMessageContainer: NSObject {
    public var cipherText: Data?
    public var counter: NSNumber?
    public var previousCounter: NSNumber?
    public var coreKey: Data?
    
    public init(cipherText: Data?, counter: NSNumber, previousCounter: NSNumber, coreKey: Data?) {
        self.cipherText = cipherText
        self.counter = counter
        self.previousCounter = previousCounter
        self.coreKey = coreKey
    }
}
