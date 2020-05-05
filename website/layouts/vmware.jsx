import DocsPage from '@hashicorp/react-docs-page'
import order from '../data/vmware-navigation.js'
import { frontMatter as data } from '../pages/vmware/**/*.mdx'
import { MDXProvider } from '@mdx-js/react'
import Head from 'next/head'
import Link from 'next/link'

const DEFAULT_COMPONENTS = {}

function VMWareLayoutWrapper(pageMeta) {
  function VMWareLayout(props) {
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
            category: 'vmware',
            currentPage: props.path,
            data,
            order,
          }}
          resourceURL={`https://github.com/hashicorp/vagrant/blob/master/website/pages/${pageMeta.__resourcePath}`}
        />
      </MDXProvider>
    )
  }

  VMWareLayout.getInitialProps = ({ asPath }) => ({ path: asPath })

  return VMWareLayout
}

export default VMWareLayoutWrapper
