const withHashicorp = require('@hashicorp/nextjs-scripts')

module.exports = withHashicorp({
  defaultLayout: true,
  transpileModules: ['is-absolute-url', '@hashicorp/react-mega-nav'],
})({
  experimental: { modern: true },
  env: {
    HASHI_ENV: process.env.HASHI_ENV || 'development',
    SEGMENT_WRITE_KEY: 'wFMyBE4PJCZttWfu0pNhYdWr7ygW0io4',
    BUGSNAG_CLIENT_KEY: 'c1d6da7a26dc367253f39fae8d83fdac',
    BUGSNAG_SERVER_KEY: 'c1d6da7a26dc367253f39fae8d83fdac',
  },
})
