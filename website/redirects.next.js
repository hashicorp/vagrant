// REDIRECTS FILE

// See the README file in this directory for documentation. Please do not
// modify or delete existing redirects without first verifying internally.
// Next.js redirect documentation: https://nextjs.org/docs/api-reference/next.config.js/redirects

module.exports = [
  { source: '/support', destination: '/', permanent: true },
  { source: '/sponsors', destination: '/', permanent: true },
  { source: '/about', destination: '/intro', permanent: true },
  {
    source: '/v1/:path*',
    destination: 'https://docs-v1.vagrantup.com/:path*',
    permanent: true,
  },
  {
    source: '/blog/:path*',
    destination: 'https://hashicorp.com/blog/:path*',
    permanent: true,
  },
  {
    source: '/download-archive/:path*',
    destination: 'https://releases.hashicorp.com/vagrant',
    permanent: true,
  },
  { source: '/intro/index', destination: '/intro', permanent: true },
  { source: '/docs/index', destination: '/docs', permanent: true },
  {
    source: '/docs/virtualbox/:path*',
    destination: '/docs/providers/virtualbox/:path*',
    permanent: true,
  },
  {
    source: '/docs/vmware/:path*',
    destination: '/docs/providers/vmware/:path*',
    permanent: true,
  },
  {
    source: '/docs/docker/:path*',
    destination: '/docs/providers/docker/:path*',
    permanent: true,
  },
  {
    source: '/docs/hyperv/:path*',
    destination: '/docs/providers/hyperv/:path*',
    permanent: true,
  },
  {
    source: '/docs/vagrant-cloud',
    destination: '/vagrant-cloud',
    permanent: true,
  },
  {
    source: '/docs/vagrant-cloud/:path*',
    destination: '/vagrant-cloud/:path*',
    permanent: true,
  },
  // Redirect "getting started" guides to Learn
  {
    source: '/(docs|intro)/getting-started',
    destination:
      'https://learn.hashicorp.com/collections/vagrant/getting-started',
    permanent: true,
  },
  {
    source: '/(docs|intro)/getting-started/project_setup',
    destination:
      'https://learn.hashicorp.com/tutorials/vagrant/getting-started-project-setup?in=vagrant/getting-started',
    permanent: true,
  },
  {
    source: '/(docs|intro)/getting-started/synced_folders',
    destination:
      'https://learn.hashicorp.com/tutorials/vagrant/getting-started-synced-folders?in=vagrant/getting-started',
    permanent: true,
  },
  {
    source: '/(docs|intro)/getting-started/:path*',
    destination:
      'https://learn.hashicorp.com/tutorials/vagrant/getting-started-:path*',
    permanent: true,
  },
  // disallow '.html' or '/index.html' in favor of cleaner, simpler paths
  { source: '/:path*/index', destination: '/:path*', permanent: true },
  { source: '/:path*.html', destination: '/:path*', permanent: true },
]
