//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import "NSData+RandomGenerator.h"

@implementation NSData(RandomGenerator)

+(NSData*)garbageDataWithLength:(int) length {
    
    UInt8* bytes = malloc(length);
    for (int i =0; i< length; i++) {
        UInt8 byte = (arc4random() % 255);
        bytes[i] = byte;
    }
    NSData * data = [NSData dataWithBytes:bytes length:length];
    free(bytes);
    
    return  data;
}

@end
