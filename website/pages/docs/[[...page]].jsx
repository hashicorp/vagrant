import { productName, productSlug } from 'data/metadata'
import DocsPage from '@hashicorp/react-docs-page'
import { getStaticGenerationFunctions } from '@hashicorp/react-docs-page/server'
import versions from 'data/version.json'
import Button from '@hashicorp/react-button'

const NAV_DATA_FILE = 'data/docs-nav-data.json'
const CONTENT_DIR = 'content/docs'
const basePath = 'docs'
const additionalComponents = { Button }

export default function DocsLayout(props) {
  return (
    <DocsPage
      product={{ name: productName, slug: productSlug }}
      baseRoute={basePath}
      staticProps={props}
      additionalComponents={additionalComponents}
      showVersionSelect={process.env.ENABLE_VERSIONED_DOCS === 'true'}
    />
  )
}

const { getStaticPaths, getStaticProps } = getStaticGenerationFunctions(
  process.env.ENABLE_VERSIONED_DOCS === 'true'
    ? {
        strategy: 'remote',
        basePath: basePath,
        fallback: 'blocking',
        revalidate: 360, // 1 hour
        product: productSlug,
        scope: { VMWARE_UTILITY_VERSION: versions.VMWARE_UTILITY_VERSION },
      }
    : {
        strategy: 'fs',
        localContentDir: CONTENT_DIR,
        navDataFile: NAV_DATA_FILE,
        product: productSlug,
        scope: { VMWARE_UTILITY_VERSION: versions.VMWARE_UTILITY_VERSION },
      }
)

export { getStaticPaths, getStaticProps }
