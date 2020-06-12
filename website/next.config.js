const withHashicorp = require('@hashicorp/nextjs-scripts')

console.log(`Environment: ${process.env.HASHI_ENV}`)

module.exports = withHashicorp({
  defaultLayout: true,
  transpileModules: ['is-absolute-url', '@hashicorp/react-mega-nav'],
})({
  experimental: { modern: true },
  env: {
    HASHI_ENV: process.env.HASHI_ENV || 'development',
    SEGMENT_WRITE_KEY: 'wFMyBE4PJCZttWfu0pNhYdWr7ygW0io4',
    BUGSNAG_CLIENT_KEY: '87a42e709789c35676b06b0d29a9075d',
    BUGSNAG_SERVER_KEY: '4acc6140aaebfab35f535a3666674a07',
  },
})
