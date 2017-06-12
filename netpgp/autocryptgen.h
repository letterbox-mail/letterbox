//
//  autocryptgen.h
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 11.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

#ifndef autocryptgen_h
#define autocryptgen_h

#include <stdio.h>
#include "netpgp-extra.h"


int mre2ee_driver_create_keypair(uint8_t* adr, char* pk, char* sk);//const char* addr);

#endif /* autocryptgen_h */
