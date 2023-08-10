// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package state

import (
	"math/rand"
	"time"
)

func init() {
	// Seed our test randomness
	rand.Seed(time.Now().UnixNano())
}
