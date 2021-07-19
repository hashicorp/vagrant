import './style.css'
import '@hashicorp/nextjs-scripts/lib/nprogress/style.css'

import NProgress from '@hashicorp/nextjs-scripts/lib/nprogress'
import createConsentManager from '@hashicorp/nextjs-scripts/lib/consent-manager'
import useAnchorLinkAnalytics from '@hashicorp/nextjs-scripts/lib/anchor-link-analytics'
import Router from 'next/router'
import HashiHead from '@hashicorp/react-head'
import Head from 'next/head'
import { ErrorBoundary } from '@hashicorp/nextjs-scripts/lib/bugsnag'
import HashiStackMenu from '@hashicorp/react-hashi-stack-menu'
import ProductSubnav from '../components/subnav'
import Footer from '../components/footer'
import Error from './_error'
import AlertBanner from '@hashicorp/react-alert-banner'
import alertBannerData, { ALERT_BANNER_ACTIVE } from 'data/alert-banner'

NProgress({ Router })
const { ConsentManager, openConsentManager } = createConsentManager({
  preset: 'oss',
})

export default function App({ Component, pageProps }) {
  useAnchorLinkAnalytics()

  return (
    <ErrorBoundary FallbackComponent={Error}>
      <HashiHead
        is={Head}
        title="Vagrant by HashiCorp"
        siteName="Vagrant by HashiCorp"
        description="Vagrant enables users to create and configure lightweight, reproducible, and
          portable development environments."
        image="https://www.vagrantup.com/img/og-image.png"
        icon={[{ href: '/favicon.ico' }]}
      />
      {ALERT_BANNER_ACTIVE && (
        <AlertBanner {...alertBannerData} product="vagrant" />
      )}
      <HashiStackMenu />
      <ProductSubnav />
      <div className="content">
        <Component {...pageProps} />
      </div>
      <Footer openConsentManager={openConsentManager} />
      <ConsentManager />
    </ErrorBoundary>
  )
}
