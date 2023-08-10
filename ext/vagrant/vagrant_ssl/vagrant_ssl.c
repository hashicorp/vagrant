/*
 * Copyright (c) HashiCorp, Inc.
 * SPDX-License-Identifier: BUSL-1.1
 */

#include "vagrant_ssl.h"

#if defined(_VAGRANT_SSL_PROVIDER_)

static VALUE vagrant_ssl_load(VALUE self) {
  OSSL_PROVIDER *legacy;
  OSSL_PROVIDER *deflt;

  legacy = OSSL_PROVIDER_load(NULL, "legacy");
  if(legacy == NULL) {
    rb_raise(rb_eStandardError, "Failed to load OpenSSL legacy provider");
    return self;
  }

  deflt = OSSL_PROVIDER_load(NULL, "default");
  if(deflt == NULL) {
    rb_raise(rb_eStandardError, "Failed to load OpenSSL default provider");
    return self;
  }
}

void Init_vagrant_ssl(void) {
  VALUE vagrant;
  vagrant = rb_define_module("Vagrant");
  rb_define_singleton_method(vagrant, "vagrant_ssl_load", vagrant_ssl_load, 0);
}

#else

void Init_vagrant_ssl(void) {}

#endif
