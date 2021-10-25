import './style.css'
import '@hashicorp/platform-util/nprogress/style.css'

import Min100Layout from '@hashicorp/react-min-100-layout'
import NProgress from '@hashicorp/platform-util/nprogress'
import usePageviewAnalytics from '@hashicorp/platform-analytics'
import createConsentManager from '@hashicorp/react-consent-manager/loader'
import useAnchorLinkAnalytics from '@hashicorp/platform-util/anchor-link-analytics'
import Router from 'next/router'
import HashiHead from '@hashicorp/react-head'
import Head from 'next/head'
import { ErrorBoundary } from '@hashicorp/platform-runtime-error-monitoring'
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
  usePageviewAnalytics()

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
      <Min100Layout footer={<Footer openConsentManager={openConsentManager} />}>
        {ALERT_BANNER_ACTIVE && (
          <AlertBanner {...alertBannerData} product="vagrant" hideOnMobile />
        )}
        <HashiStackMenu />
        <ProductSubnav />
        <div className="content">
          <Component {...pageProps} />
        </div>
      </Min100Layout>
      <ConsentManager />
    </ErrorBoundary>
  )
}
