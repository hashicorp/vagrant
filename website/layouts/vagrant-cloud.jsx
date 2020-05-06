import DocsPage from '@hashicorp/react-docs-page'
import order from '../data/cloud-navigation.js'
import { frontMatter as data } from '../pages/vagrant-cloud/**/*.mdx'
import { MDXProvider } from '@mdx-js/react'
import Head from 'next/head'
import Link from 'next/link'
import Button from '@hashicorp/react-button'
import Tabs, { Tab } from '../components/tabs'

const DEFAULT_COMPONENTS = { Button, Tabs, Tab }

function CloudLayoutWrapper(pageMeta) {
  function CloudLayout(props) {
    return (
      <MDXProvider components={DEFAULT_COMPONENTS}>
        <DocsPage
          {...props}
          product="vagrant"
          head={{
            is: Head,
            title: `${pageMeta.page_title} | Vagrant by HashiCorp`,
            description: pageMeta.description,
            siteName: 'Vagrant by HashiCorp',
          }}
          sidenav={{
            Link,
            category: 'Cloud',
            currentPage: props.path,
            data,
            order,
          }}
          resourceURL={`https://github.com/hashicorp/vagrant/blob/master/website/pages/${pageMeta.__resourcePath}`}
        />
      </MDXProvider>
    )
  }

  CloudLayout.getInitialProps = ({ asPath }) => ({ path: asPath })

  return CloudLayout
}

export default CloudLayoutWrapper
