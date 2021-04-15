import { VERSION } from 'data/version'
import { productSlug } from 'data/metadata'
import ProductDownloadsPage from '@hashicorp/react-product-downloads-page'
import { generateStaticProps } from '@hashicorp/react-product-downloads-page/server'
import Link from 'next/link'
import s from './style.module.css'

export default function DownloadsPage(staticProps) {
  return (
    <ProductDownloadsPage
      getStartedDescription="Follow step-by-step tutorials on the essentials of Vagrant."
      getStartedLinks={[
        {
          label: 'Quick Start',
          href:
            'https://learn.hashicorp.com/tutorials/vagrant/getting-started-index',
        },
        {
          label: 'Install and Specify a Box',
          href:
            'https://learn.hashicorp.com/tutorials/vagrant/getting-started-boxes',
        },
        {
          label: 'Configure the Network',
          href:
            'https://learn.hashicorp.com/tutorials/vagrant/getting-started-networking',
        },
        {
          label: 'View all Vagrant tutorials',
          href: 'https://learn.hashicorp.com/vagrant',
        },
      ]}
      logo={
        <img
          className={s.logo}
          alt="Vagrant"
          src={require('./img/vagrant-logo.svg')}
        />
      }
      tutorialLink={{
        href: 'https://learn.hashicorp.com/vagrant',
        label: 'View Tutorials at HashiCorp Learn',
      }}
      merchandisingSlot={
        <Link href="/vmware/downloads">
          <a>&raquo; Download VMware Utility</a>
        </Link>
      }
      {...staticProps}
    />
  )
}

export async function getStaticProps() {
  return generateStaticProps({
    product: productSlug,
    latestVersion: VERSION,
  })
}
