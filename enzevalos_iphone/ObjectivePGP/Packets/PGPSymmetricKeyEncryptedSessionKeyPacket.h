//
//  PGPSymmetricKeyEncryptedSessionKeyPacket.h
//  ObjectivePGP
//
//  Created by Oliver Wiese on 11.10.17.
//  Copyright © 2017 Marcin Krzyżanowski. All rights reserved.
//

#import "PGPPacket.h"
#import "PGPExportableProtocol.h"
#import "PGPS2K.h"

NS_ASSUME_NONNULL_BEGIN


@interface PGPSymmetricKeyEncryptedSessionKeyPacket : PGPPacket <NSCopying, PGPExportable>
@property (nonatomic) UInt8 version;
@property (nonatomic) PGPSymmetricAlgorithm symmetricKeyAlgorithm;
@property (nonatomic) PGPS2K *s2k;

@end

NS_ASSUME_NONNULL_END
