import s from './style.module.css'
import { VMWARE_UTILITY_VERSION } from 'data/version'
import ProductDownloadsPage from '@hashicorp/react-product-downloads-page'
import { generateStaticProps } from '@hashicorp/react-product-downloads-page/server'
import Head from 'next/head'
import HashiHead from '@hashicorp/react-head'

export default function DownloadsPage(staticProps) {
  return (
    <>
      <ProductDownloadsPage
        getStartedDescription="Follow step-by-step tutorials on the essentials of Vagrant VMWare Utility."
        getStartedLinks={[
          {
            label: 'Installation Instructions',
            href:
              'https://www.vagrantup.com/docs/providers/vmware/installation',
          },
          {
            label: 'Community Resources',
            href: 'https://www.vagrantup.com/community',
          },
          {
            label: 'View all Vagrant tutorials',
            href: 'https://learn.hashicorp.com/vagrant',
          },
        ]}
        logo={<p className={s.notALogo}>Vagrant vmware Utility</p>}
        tutorialLink={{
          href: 'https://learn.hashicorp.com/vagrant',
          label: 'View Tutorials at HashiCorp Learn',
        }}
        packageManagerOverrides={[
          // Note: Duplicate Homebrew entries target
          // both macOS and Linux. If one is removed,
          // then Homebrew will show up under the Linux tab.
          {
            label: 'Homebrew',
            os: 'NONE--IGNORE',
          },
          {
            label: 'Homebrew',
            os: 'NONE--IGNORE',
          },
          {
            label: 'Amazon Linux',
            os: 'NONE--IGNORE',
          },
          {
            label: 'Fedora',
            os: 'NONE--IGNORE',
          },
          {
            label: 'Ubuntu/Debian',
            os: 'NONE--IGNORE',
          },
          {
            label: 'CentOS/RHEL',
            os: 'NONE--IGNORE',
          },
        ]}
        {...staticProps}
      />
      {/* Override default ProductDownloader title */}
      <HashiHead
        is={Head}
        title="VMware Utility Downloads | Vagrant by HashiCorp"
      />
    </>
  )
}

export async function getStaticProps() {
  return await generateStaticProps({
    product: 'vagrant-vmware-utility',
    latestVersion: VMWARE_UTILITY_VERSION,
  })
}
