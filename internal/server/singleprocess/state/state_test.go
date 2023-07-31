// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package state

import (
	"math/rand"
	"time"
)

func init() {
	// Seed our test randomness
	rand.Seed(time.Now().UnixNano())
}
