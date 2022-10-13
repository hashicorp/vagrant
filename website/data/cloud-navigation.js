// The root folder for this documentation category is `pages/docs`
//
// - A string refers to the name of a file
// - A "category" value refers to the name of a directory
// - All directories must have an "index.mdx" file to serve as
//   the landing page for the category, or a "name" property to
//   serve as the category title in the sidebar

export default [
  { title: 'Back to Vagrant Documentation', href: '/docs' },
  {
    category: 'boxes',
    content: [
      'catalog',
      'create',
      'create-version',
      'distributing',
      'lifecycle',
      'private',
      'release-workflow',
      'using',
    ],
  },
  {
    category: 'organizations',
    content: ['create', 'migrate', 'authentication-policy'],
  },
  { category: 'users', content: ['authentication', 'recovery'] },
  'request-limits',
  'support',
  'api',
]
