module.exports = {
  ...require('@hashicorp/nextjs-scripts/.stylelintrc.js'),
  extends: ['stylelint-config-css-modules'],
  rules: {
    'selector-pseudo-class-no-unknown': [
      true,
      {
        ignorePseudoClasses: ['first', 'last', 'global'],
      },
    ],
  },
}
