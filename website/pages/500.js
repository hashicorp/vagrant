import s from './404.module.css'
import Link from 'next/link'
import { useEffect } from 'react'

export default function Custom500Error() {
  useEffect(() => {
    if (
      typeof window !== 'undefined' &&
      typeof window?.analytics?.track === 'function' &&
      typeof window?.document?.referrer === 'string' &&
      typeof window?.location?.href === 'string'
    )
      window.analytics.track(window.location.href, {
        category: '500 Response',
        label: window.document.referrer || 'No Referrer',
      })
  }, [])

  return (
    <div className={s.root}>
      <h1 className={s.heading}>Something went wrong</h1>
      <p>
        We&apos;re sorry, but we can&apos;t render the page you&apos;re looking
        for.
      </p>
      <p>
        <Link href="/">
          <a>Back to Home</a>
        </Link>
      </p>
    </div>
  )
}
