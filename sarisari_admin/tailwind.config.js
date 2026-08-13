/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        status: {
          active: '#16a34a',
          paused: '#d97706',
          disabled: '#dc2626',
          deleted: '#6b7280',
        },
      },
    },
  },
  plugins: [],
};
