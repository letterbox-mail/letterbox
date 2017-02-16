//
//  PGPTemporaryDecryptionObject.h
//  enzevalos_iphone
//
//  Created by jakobsbode on 16.02.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

#import "PGPOnePassSignaturePacket.h"
#import "PGPSignaturePacket.h"

@interface PGPTemporaryDecryptionObject : NSObject

@property (readonly, nullable) PGPOnePassSignaturePacket *onePassSignaturePacket;
@property (readonly, nullable) NSString *incompleteKeyID;
@property (readonly, nullable) PGPSignaturePacket *signaturePacket;
@property (readonly, nullable) NSData *plaintextData;

- (nonnull instancetype)init:(nullable PGPSignaturePacket *)signaturePacket plaintextData:(nullable NSData *)plaintextData;

@end
