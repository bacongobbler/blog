/** @type {import('tailwindcss').Config} */

const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    "content/**/*.md",
    "layouts/**/*.html",
    'static/**/*.*'
  ],
  theme: {
    fontFamily: {
      'sans': ['Raleway', ...defaultTheme.fontFamily.sans],
    },
    extend: {},
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}

