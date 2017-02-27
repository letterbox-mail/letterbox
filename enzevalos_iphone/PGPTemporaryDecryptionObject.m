//
//  PGPTemporaryDecryptionObject.m
//  enzevalos_iphone
//
//  Created by jakobsbode on 16.02.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import "PGPTemporaryDecryptionObject.h"

@implementation PGPTemporaryDecryptionObject

- (instancetype)init:(PGPSignaturePacket*)signaturePacket plaintextData:(NSData *)plaintextData
{
    self->_signaturePacket = signaturePacket;
    self->_plaintextData = plaintextData;
    if (signaturePacket != nil) {
        self->_incompleteKeyID = signaturePacket.issuerKeyID.longKeyString;
    }else {
        self->_incompleteKeyID = nil;
    }
    
    return self;
}

@end
