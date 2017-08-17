//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <Foundation/Foundation.h>

@protocol SymmetricCipher;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"

@interface AESCBCSymmetricCipher : NSObject<SymmetricCipher>

@end

#pragma clang diagnostic pop
