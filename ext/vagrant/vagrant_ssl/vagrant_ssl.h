/*
 * Copyright (c) HashiCorp, Inc.
 * SPDX-License-Identifier: BUSL-1.1
 */

#if !defined(_VAGRANT_SSL_H_)
#define _VAGRANT_SSL_H_

#include <openssl/opensslv.h>
#if OPENSSL_VERSION_NUMBER >= (3 << 28)
#define _VAGRANT_SSL_PROVIDER_

#include <ruby.h>
#include <openssl/provider.h>
#endif

void Init_vagrant_ssl(void);

#endif
