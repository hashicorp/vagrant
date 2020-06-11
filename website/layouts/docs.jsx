import DocsPage from '@hashicorp/react-docs-page'
import order from '../data/docs-navigation.js'
import { frontMatter as data } from '../pages/docs/**/*.mdx'
import Head from 'next/head'
import Link from 'next/link'
import { createMdxProvider } from '@hashicorp/nextjs-scripts/lib/providers/docs'
import Button from '@hashicorp/react-button'

const MDXProvider = createMdxProvider({
  product: 'vagrant',
  additionalComponents: { Button },
})

function DocsLayoutWrapper(pageMeta) {
  function DocsLayout(props) {
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
            category: 'docs',
            currentPage: props.path,
            data,
            order,
          }}
          resourceURL={`https://github.com/hashicorp/vagrant/blob/master/website/pages/${pageMeta.__resourcePath}`}
        />
      </MDXProvider>
    )
  }

  DocsLayout.getInitialProps = ({ asPath }) => ({ path: asPath })

  return DocsLayout
}

export default DocsLayoutWrapper
