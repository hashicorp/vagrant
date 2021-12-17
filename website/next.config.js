const withHashicorp = require('@hashicorp/platform-nextjs-plugin')
const redirects = require('./redirects.next')

// log out our primary environment variables for clarity in build logs
console.log(`HASHI_ENV: ${process.env.HASHI_ENV}`)
console.log(`NODE_ENV: ${process.env.NODE_ENV}`)
console.log(`VERCEL_ENV: ${process.env.VERCEL_ENV}`)
console.log(`MKTG_CONTENT_API: ${process.env.MKTG_CONTENT_API}`)
console.log(`ENABLE_VERSIONED_DOCS: ${process.env.ENABLE_VERSIONED_DOCS}`)

module.exports = withHashicorp({
  defaultLayout: true,
  nextOptimizedImages: true,
})({
  svgo: { plugins: [{ removeViewBox: false }] },
  redirects: () => redirects,
  env: {
    HASHI_ENV: process.env.HASHI_ENV || 'development',
    SEGMENT_WRITE_KEY: 'wFMyBE4PJCZttWfu0pNhYdWr7ygW0io4',
    BUGSNAG_CLIENT_KEY: '87a42e709789c35676b06b0d29a9075d',
    BUGSNAG_SERVER_KEY: '4acc6140aaebfab35f535a3666674a07',
    ENABLE_VERSIONED_DOCS: process.env.ENABLE_VERSIONED_DOCS || false,
  },
})
