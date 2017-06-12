//
//  KeyGen.c
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 11.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

#include "KeyGen.h"
#include "netpgp-extra.h"

/*******************************************************************************
 * Key generatation
 ******************************************************************************/


static unsigned add_key_prefs(pgp_create_sig_t *sig)
{
    /* similar to pgp_add_key_prefs(), Mimic of GPG default settings, limited to supported algos */
    return
    /* Symmetric algo prefs */
    pgp_write_ss_header(sig->output, 6, PGP_PTAG_SS_PREFERRED_SKA) &&
    pgp_write_scalar(sig->output, PGP_SA_AES_256, 1) &&
    pgp_write_scalar(sig->output, PGP_SA_AES_128, 1) &&
    pgp_write_scalar(sig->output, PGP_SA_CAST5, 1) &&
    pgp_write_scalar(sig->output, PGP_SA_TRIPLEDES, 1) &&
    pgp_write_scalar(sig->output, PGP_SA_IDEA, 1) &&
    
    /* Hash algo prefs, the first algo is the preferred algo */
    pgp_write_ss_header(sig->output, 6, PGP_PTAG_SS_PREFERRED_HASH) &&
    pgp_write_scalar(sig->output, PGP_HASH_SHA256, 1) &&
    pgp_write_scalar(sig->output, PGP_HASH_SHA384, 1) &&
    pgp_write_scalar(sig->output, PGP_HASH_SHA512, 1) &&
    pgp_write_scalar(sig->output, PGP_HASH_SHA224, 1) &&
    pgp_write_scalar(sig->output, PGP_HASH_SHA1, 1) && /* Edit for Autocrypt/Delta Chat: due to the weak SHA1, it should not be preferred */
    
    /* Compression algo prefs */
    pgp_write_ss_header(sig->output, 2/*1+number of following items*/, PGP_PTAG_SS_PREF_COMPRESS) &&
    pgp_write_scalar(sig->output, PGP_C_ZLIB, 1) /*&& -- not sure if Delta Chat will support bzip2 on all platforms, however, this is not that important as typical files are compressed themselves and text is not that big
                                                  pgp_write_scalar(sig->output, PGP_C_BZIP2, 1) -- if you re-enable this, do not forget to modifiy the header count*/;
}


static void add_selfsigned_userid(pgp_key_t *skey, pgp_key_t *pkey, const uint8_t *userid, time_t key_expiry)
{
    /* similar to pgp_add_selfsigned_userid() which, however, uses different key flags */
    pgp_create_sig_t	*sig;
    pgp_subpacket_t	 sigpacket;
    pgp_memory_t		*mem_sig = NULL;
    pgp_output_t		*sigoutput = NULL;
    
    /* create sig for this pkt */
    sig = pgp_create_sig_new();
    pgp_sig_start_key_sig(sig, &skey->key.seckey.pubkey, NULL, userid, PGP_CERT_POSITIVE);
    
    pgp_add_creation_time(sig, time(NULL));
    pgp_add_key_expiration_time(sig, key_expiry);
    pgp_add_primary_userid(sig, 1);
    pgp_add_key_flags(sig, PGP_KEYFLAG_SIGN_DATA|PGP_KEYFLAG_CERT_KEYS);
    add_key_prefs(sig);
    pgp_add_key_features(sig); /* will add 0x01 - modification detection */
    
    pgp_end_hashed_subpkts(sig);
    
    pgp_add_issuer_keyid(sig, skey->pubkeyid); /* the issuer keyid is not hashed by definition */
    
    pgp_setup_memory_write(&sigoutput, &mem_sig, 128);
    pgp_write_sig(sigoutput, sig, &skey->key.seckey.pubkey, &skey->key.seckey);
    
    /* add this packet to key */
    sigpacket.length = pgp_mem_len(mem_sig);
    sigpacket.raw = pgp_mem_data(mem_sig);
    
    /* add user id and signature to key */
    pgp_update_userid(skey, userid, &sigpacket, &sig->sig.info);
    if(pkey) {
        pgp_update_userid(pkey, userid, &sigpacket, &sig->sig.info);
    }
    
    /* cleanup */
    pgp_create_sig_delete(sig);
    pgp_output_delete(sigoutput);
    pgp_memory_free(mem_sig);
}


static void add_subkey_binding_signature(pgp_subkeysig_t* p, pgp_key_t* primarykey, pgp_key_t* subkey, pgp_key_t* seckey)
{
    /*add "0x18: Subkey Binding Signature" packet, PGP_SIG_SUBKEY */
    pgp_create_sig_t* sig;
    pgp_output_t*     sigoutput = NULL;
    pgp_memory_t*     mem_sig = NULL;
    
    sig = pgp_create_sig_new();
    pgp_sig_start_key_sig(sig, &primarykey->key.pubkey, &subkey->key.pubkey, NULL, PGP_SIG_SUBKEY);
    
    pgp_add_creation_time(sig, time(NULL));
    pgp_add_key_expiration_time(sig, 0);
    pgp_add_key_flags(sig, PGP_KEYFLAG_ENC_STORAGE|PGP_KEYFLAG_ENC_COMM); /* NB: algo/hash/compression preferences are not added to subkeys */
    
    pgp_end_hashed_subpkts(sig);
    
    pgp_add_issuer_keyid(sig, seckey->pubkeyid); /* the issuer keyid is not hashed by definition */
    
    pgp_setup_memory_write(&sigoutput, &mem_sig, 128);
    pgp_write_sig(sigoutput, sig, &seckey->key.seckey.pubkey, &seckey->key.seckey);
    
    p->subkey         = primarykey->subkeyc-1; /* index of subkey in array */
    p->packet.length  = mem_sig->length;
    p->packet.raw     = mem_sig->buf; mem_sig->buf = NULL; /* move ownership to packet */
    copy_sig_info(&p->siginfo, &sig->sig.info); /* not sure, if this is okay, however, siginfo should be set up, otherwise we get "bad info-type" errors */
    
    pgp_create_sig_delete(sig);
    pgp_output_delete(sigoutput);
    free(mem_sig); /* do not use pgp_memory_free() as this would also free mem_sig->buf which is owned by the packet */
}


int mre2ee_driver_create_keypair(const char* addr)
{
    int              success = 0;
    pgp_key_t        seckey, pubkey, subkey;
    uint8_t          subkeyid[PGP_KEY_ID_SIZE];
    uint8_t*         user_id = NULL;
    pgp_memory_t     *pubmem = pgp_memory_new(), *secmem = pgp_memory_new();
    pgp_output_t     *pubout = pgp_output_new(), *secout = pgp_output_new();
    
    memset(&seckey, 0, sizeof(pgp_key_t));
    memset(&pubkey, 0, sizeof(pgp_key_t));
    memset(&subkey, 0, sizeof(pgp_key_t));
    
    if( addr==NULL || pubmem==NULL || secmem==NULL || pubout==NULL || secout==NULL ) {
        goto cleanup;
    }
    
    /* Generate User ID.  For convention, use the same address as given in `Autocrypt: to=...` in angle brackets
     (RFC 2822 grammar angle-addr, see also https://autocrypt.org/en/latest/level0.html#type-p-openpgp-based-key-data )
     We do not add the name to the ID for the following reasons:
     - privacy
     - the name may be changed
     - shorter keys
     - the name is already taken from From:
     - not Autocrypt:-standard */
    user_id = (uint8_t*) printf("<%s>", addr);
    
    /* generate two keypairs */
    if( !pgp_rsa_generate_keypair(&seckey, 2048/*bits*/, 65537UL/*e*/, NULL, NULL, NULL, 0)
       || !pgp_rsa_generate_keypair(&subkey, 2048/*bits*/, 65537UL/*e*/, NULL, NULL, NULL, 0) ) {
        goto cleanup;
    }
    
    
    /* Create public key, bind public subkey to public key
     ------------------------------------------------------------------------ */
    
    pubkey.type = PGP_PTAG_CT_PUBLIC_KEY;
    pgp_pubkey_dup(&pubkey.key.pubkey, &seckey.key.pubkey);
    memcpy(pubkey.pubkeyid, seckey.pubkeyid, PGP_KEY_ID_SIZE);
    pgp_fingerprint(&pubkey.pubkeyfpr, &seckey.key.pubkey, 0);
    add_selfsigned_userid(&seckey, &pubkey, (const uint8_t*)user_id, 0/*never expire*/);
    
    EXPAND_ARRAY((&pubkey), subkey);
    {
        pgp_subkey_t* p = &pubkey.subkeys[pubkey.subkeyc++];
        pgp_pubkey_dup(&p->key.pubkey, &subkey.key.pubkey);
        pgp_keyid(subkeyid, PGP_KEY_ID_SIZE, &pubkey.key.pubkey, PGP_HASH_SHA1);
        memcpy(p->id, subkeyid, PGP_KEY_ID_SIZE);
    }
    
    EXPAND_ARRAY((&pubkey), subkeysig);
    add_subkey_binding_signature(&pubkey.subkeysigs[pubkey.subkeysigc++], &pubkey, &subkey, &seckey);
    
    
    /* Create secret key, bind secret subkey to secret key
     ------------------------------------------------------------------------ */
    
    EXPAND_ARRAY((&seckey), subkey);
    {
        pgp_subkey_t* p = &seckey.subkeys[seckey.subkeyc++];
        pgp_seckey_dup(&p->key.seckey, &subkey.key.seckey);
        pgp_keyid(subkeyid, PGP_KEY_ID_SIZE, &seckey.key.pubkey, PGP_HASH_SHA1);
        memcpy(p->id, subkeyid, PGP_KEY_ID_SIZE);
    }
    
    EXPAND_ARRAY((&seckey), subkeysig);
    add_subkey_binding_signature(&seckey.subkeysigs[seckey.subkeysigc++], &seckey, &subkey, &seckey);
    
    
    /* Done with key generation, write binary keys to memory
     ------------------------------------------------------------------------ */
    
    pgp_writer_set_memory(pubout, pubmem);
    if( !pgp_write_xfer_key(pubout, &pubkey, 0/*armored*/)
       || pubmem->buf == NULL || pubmem->length <= 0 ) {
        goto cleanup;
    }
    
    pgp_writer_set_memory(secout, secmem);
    if( !pgp_write_xfer_key(secout, &seckey, 0/*armored*/)
       || secmem->buf == NULL || secmem->length <= 0 ) {
        goto cleanup;
    }
    
    //mrkey_set_from_raw(ret_public_key, pubmem->buf, pubmem->length, MR_PUBLIC);
    //mrkey_set_from_raw(ret_private_key, secmem->buf, secmem->length, MR_PRIVATE);
    
    success = 1;
    
cleanup:
    if( pubout ) { pgp_output_delete(pubout); }
    if( secout ) { pgp_output_delete(secout); }
    if( pubmem ) { pgp_memory_free(pubmem); }
    if( secmem ) { pgp_memory_free(secmem); }
    pgp_key_free(&seckey); /* not: pgp_keydata_free() which will also free the pointer itself (we created it on the stack) */
    pgp_key_free(&pubkey);
    pgp_key_free(&subkey);
    free(user_id);
    return success;
}


