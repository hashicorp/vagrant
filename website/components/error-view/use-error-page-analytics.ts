import { useEffect } from 'react'

/**
 * Given an error category to record,
 * make a call to window.analytics.track on mount
 * to record the specified error category at the
 * current window.location.href.
 *
 * Relies on window.analytics.track() being a valid function
 * which can be called as window.analytics.track(href, { category, label }).
 */
export default function useErrorPageAnalytics(
  /** The type of error. Used to send specific category values
   * to window.analytics.track. */
  statusCode: number
): void {
  useEffect(() => {
    if (
      typeof window !== 'undefined' &&
      typeof window?.analytics?.track === 'function' &&
      typeof window?.document?.referrer === 'string' &&
      typeof window?.location?.href === 'string'
    )
      window.analytics.track(window.location.href, {
        category: `${statusCode} Response`,
        label: window.document.referrer || 'No Referrer',
      })
  }, [])
}
