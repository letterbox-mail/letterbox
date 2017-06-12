//
//  PGPKeyGeneration.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation


public func createKey(userID:String){
    var adr: UInt8
    adr = 8
   var pk: Array<CChar> = Array(repeating: 32, count: 4048)
   var sk: Array<CChar> = Array(repeating: 32, count: 4048)
   
    print("CreateKey")
    mre2ee_driver_create_keypair(&adr, &pk, &sk)
    print("###########")
    
    
    
}

public func generateAutocryptSecretKey(userID: String){
    var secretKey = pgp_key_t()
    var subKey = pgp_key_t()
    var publicKey = pgp_key_t()
    
    memset(&secretKey, 0, MemoryLayout<pgp_key_t>.size)
    memset(&subKey, 0, MemoryLayout<pgp_key_t>.size)
    memset(&publicKey, 0, MemoryLayout<pgp_key_t>.size)

    pgp_rsa_generate_keypair(&secretKey, 2048, 65537, nil, nil, nil, 0)
    pgp_rsa_generate_keypair(&subKey, 2048, 65537, nil, nil, nil, 0)
    
    publicKey.type = PGP_PTAG_CT_PUBLIC_KEY
    publicKey.key.pubkey = secretKey.key.pubkey

    pgp_fingerprint(&publicKey.pubkeyfpr, &secretKey.key.pubkey, PGP_HASH_SHA256)
    
    bindSigKey(key: &publicKey, sigKey: &subKey, secKey: &secretKey)
    
    print("PK: \(publicKey.key.pubkey.birthtime)")
    
}


private func bindSigKey( key: inout pgp_key_t, sigKey: inout pgp_key_t, secKey: inout pgp_key_t){
    var primKey = key
    var subKey = sigKey
    var signature = pgp_create_sig_new()
    var resultSig: UnsafeMutablePointer<pgp_output_t>?
    
    var mem: UnsafeMutablePointer<pgp_memory_t>?
    
    pgp_sig_start_key_sig(signature, &primKey.key.pubkey, &subKey.key.pubkey, nil, PGP_SIG_SUBKEY)
    pgp_add_creation_time(signature, time(nil))
    pgp_add_key_expiration_time(signature, 0)
    pgp_add_key_flags(signature,UInt8(PGP_KEYFLAG_ENC_COMM.rawValue)) // add  PGP_KEYFLAG_ENC_STORAGE ???
    
    pgp_end_hashed_subpkts(signature)
    pgp_add_issuer_keyid(signature, &secKey.pubkeyid.0)
    
    pgp_setup_memory_write(&resultSig, &mem, 128)
    pgp_write_sig(resultSig, signature, &secKey.key.seckey.pubkey, &secKey.key.seckey)

    //TODO: Consider pk???
    
    pgp_create_sig_delete(signature)
    pgp_output_delete(resultSig)
    free(mem)
}




