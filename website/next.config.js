const withHashicorp = require('@hashicorp/platform-nextjs-plugin')
const redirects = require('./redirects.next')

console.log(`Environment: ${process.env.HASHI_ENV}`)

module.exports = withHashicorp({
  defaultLayout: true,
  transpileModules: [
    'is-absolute-url',
    '@hashicorp/react-image',
    '@hashicorp/versioned-docs',
  ],
})({
  svgo: { plugins: [{ removeViewBox: false }] },
  redirects: () => redirects,
  env: {
    HASHI_ENV: process.env.HASHI_ENV || 'development',
    SEGMENT_WRITE_KEY: 'wFMyBE4PJCZttWfu0pNhYdWr7ygW0io4',
    BUGSNAG_CLIENT_KEY: '87a42e709789c35676b06b0d29a9075d',
    BUGSNAG_SERVER_KEY: '4acc6140aaebfab35f535a3666674a07',
  },
})
