//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import "CryptoDebug.h"

@implementation NSMutableString (DebugDescription)

- (void)addLine:(NSString *)line indentationLevel:(NSInteger)indentation
{
    [self appendString:@"\n"];
    for (NSInteger i = 0; i < indentation; i++) {
        [self appendString:@" "];
    }
    [self appendString:line];
}

@end

@implementation SessionState (DebugDescription)

- (NSString *)debugDescriptionWithIndentation:(NSInteger)indentation;
{
    NSMutableString *description = [NSMutableString new];
    
    [description addLine:self.description indentationLevel:indentation];
    [description addLine:[NSString stringWithFormat:@"Remote registration Id: %@", self.remoteRegistrationId] indentationLevel:indentation+1];
    [description addLine:[NSString stringWithFormat:@"Local registration Id: %@", self.localRegistrationId] indentationLevel:indentation+1];
    [description addLine:[NSString stringWithFormat:@"Previous counter: %@", @(self.previousCounter)] indentationLevel:indentation+1];
    [description addLine:[NSString stringWithFormat:@"Base key: %@", self.aliceBaseKey] indentationLevel:indentation+1];
    [description addLine:[NSString stringWithFormat:@"Root key: %@", self.initalizedState.rootKey.keyData] indentationLevel:indentation+1];
    [description addLine:[NSString stringWithFormat:@"Remote Id key: %@", self.initalizedState.remoteIdentityKey] indentationLevel:indentation+1];
    [description addLine:[NSString stringWithFormat:@"Local Id key: %@", self.initalizedState.localIdentityKey] indentationLevel:indentation+1];
    
    [description addLine:@"Sending chain:" indentationLevel:indentation+1];
    
    //[description addLine:[NSString stringWithFormat:@"Index: %@", @(self.sendingChain.chainKey.index)] indentationLevel:indentation+2];
    //[description addLine:[NSString stringWithFormat:@"Key: %@", self.sendingChain.chainKey.key] indentationLevel:indentation+2];
    [description addLine:@"Message key:" indentationLevel:indentation+2];
    //[description appendString:[self.sendingChain.chainKey.messageKeys debugDescriptionWithIndentation:indentation+3]];
    
    [description addLine:@"Receiving chains:" indentationLevel:indentation+1];
    /*for (ReceivingChain *receivingChain in self.receivingChains) {
        [description addLine:@"[]" indentationLevel:indentation+2];
        [description addLine:[NSString stringWithFormat:@"Index: %@", @(receivingChain.chainKey.index)] indentationLevel:indentation+3];
        [description addLine:[NSString stringWithFormat:@"Key: %@", receivingChain.chainKey.key] indentationLevel:indentation+3];
        [description addLine:@"Message key:" indentationLevel:indentation+3];
        [description appendString:[receivingChain.chainKey.messageKeys debugDescriptionWithIndentation:indentation+4]];
        
        [description addLine:@"Old Message keys (Out of order only):" indentationLevel:indentation+3];
        for (MessageKeys *messageKey in receivingChain.messageKeysList) {
            [description addLine:@"[]" indentationLevel:indentation+4];
            [description appendString:[messageKey debugDescriptionWithIndentation:indentation+5]];
        }
        if (receivingChain.messageKeysList.count == 0) {
            [description addLine:@"<empty>" indentationLevel:indentation+4];
        }
    }*/
//    if (self.receivingChains.count == 0) {
//        [description addLine:@"<empty>" indentationLevel:indentation+2];
//    }
    
    if (self.pendingInitKey) {
        [description addLine:@"Pending initKey:" indentationLevel:indentation+1];
        [description addLine:[NSString stringWithFormat:@"Pre key id: %@", @(self.pendingInitKey.initKeyId)] indentationLevel:indentation+2];
        [description addLine:[NSString stringWithFormat:@"Signed init key id: %@", self.pendingInitKey.signedInitKeyId] indentationLevel:indentation+2];
        [description addLine:[NSString stringWithFormat:@"Base key: %@", self.pendingInitKey.baseKey] indentationLevel:indentation+2];
    } else {
        [description addLine:@"Pending initKey: None" indentationLevel:indentation+1];
    }
    
    return description.copy;
}

@end

@implementation MessageKeys (DebugDescription)

- (NSString *)debugDescriptionWithIndentation:(NSInteger)indentation
{
    NSMutableString *description = [NSMutableString new];
    [description addLine:[NSString stringWithFormat:@"Index: %@", @(self.index)] indentationLevel:indentation];
    [description addLine:[NSString stringWithFormat:@"Cipher key: %@", self.cipherKey] indentationLevel:indentation];
    [description addLine:[NSString stringWithFormat:@"Mac key: %@", self.macKey] indentationLevel:indentation];
    [description addLine:[NSString stringWithFormat:@"Init vector: %@", self.iv] indentationLevel:indentation];
    return description.copy;
}

@end
