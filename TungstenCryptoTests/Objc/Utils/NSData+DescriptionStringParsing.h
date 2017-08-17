//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <Foundation/Foundation.h>

@interface NSData (DescriptionStringParsing)
+ (NSData *)dataFromDescriptionString:(NSString *)string;
- (NSData *)dataFromDescriptionString:(NSString *)string;
@end
