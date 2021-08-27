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
        pageTitle="Download Vagrant vmware Utility"
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
        showPackageManagers={false}
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
