// tailwind.config.js
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/**/*.html.erb',
    './app/components/**/*.rb',
  ],
  safelist: [
    'text-yellow-500',
    'hover:text-yellow-800',
    'text-red-500',
    'hover:text-red-800',
    'text-green-500',
    'hover:text-green-800',
    'text-blue-500',
    'hover:text-blue-800',
  ],
  theme: {
    extend: {
      fontFamily: {
        inter: ['Inter', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
