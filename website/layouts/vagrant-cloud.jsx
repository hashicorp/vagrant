import DocsPage from '@hashicorp/react-docs-page'
import order from '../data/cloud-navigation.js'
import { frontMatter as data } from '../pages/vagrant-cloud/**/*.mdx'
import { createMdxProvider } from '@hashicorp/nextjs-scripts/lib/providers/docs'
import Head from 'next/head'
import Link from 'next/link'

const MDXProvider = createMdxProvider({ product: 'vagrant' })

function CloudLayoutWrapper(pageMeta) {
  function CloudLayout(props) {
    return (
      <MDXProvider>
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
            category: 'vagrant-cloud',
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
