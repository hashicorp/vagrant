// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package state

import (
	"sync"

	validation "github.com/go-ozzo/ozzo-validation/v4"
	"github.com/hashicorp/go-memdb"
)

type pruneOp struct {
	lock         *sync.Mutex
	table, index string
	indexArgs    []interface{}
	max          int
	cur          *int
	check        func(val interface{}) bool
}

func (p *pruneOp) Validate() error {
	return validation.ValidateStruct(p,
		validation.Field(&p.lock, validation.Required),
		validation.Field(&p.table, validation.Required),
		validation.Field(&p.index, validation.Required),
		validation.Field(&p.cur, validation.NilOrNotEmpty),
	)
}

// pruneOld uses the types in op to scan the table indicated and prune old records.
// The op's check function can allow the process to skip records that shouldn't be
// pruned regardless of their age.
func pruneOld(memTxn *memdb.Txn, op pruneOp) (int, error) {
	if err := op.Validate(); err != nil {
		return 0, err
	}

	op.lock.Lock()

	// Easy enough, just exit if we haven't hit the maximum
	if *op.cur <= op.max {
		op.lock.Unlock()
		return 0, nil
	}

	// Calculate how many jobs we need to prune to get back to the maximum.
	pruneCnt := *op.cur - op.max

	// Unlock the prune lock for the bulk of the work so we don't prevent new work
	// from starting while the prune is taking place.
	op.lock.Unlock()

	// Now we iterate the jobs, starting we the queue time that is furtherest in the past
	// (ie, delete the oldest records first).
	iter, err := memTxn.LowerBound(op.table, op.index, op.indexArgs...)
	if err != nil {
		return 0, err
	}

	// Track the total values deleted separately because we can exit early
	// and so we might want to prune, say, 100 we might only be able to prune 50
	// and need to know the exact number.
	var deleted int

pruning:
	for {
		raw := iter.Next()
		if raw == nil {
			break
		}

		if op.check != nil && op.check(raw) {
			continue pruning
		}

		// otherwise, prune this job! Once we've pruned enough jobs to get back
		// to the maximum, we stop pruning.
		pruneCnt--

		err = memTxn.Delete(op.table, raw)
		if err != nil {
			return 0, err
		}

		deleted++
		if pruneCnt <= 0 {
			break
		}
	}

	// Grab the lock and update cur value
	op.lock.Lock()
	defer op.lock.Unlock()

	// We subject the diff here because while prune was running, new jobs
	// can get scheduled and thusly we might not actually remove the same
	// percentage of jobs as we expect.
	*op.cur -= deleted

	return deleted, nil
}
