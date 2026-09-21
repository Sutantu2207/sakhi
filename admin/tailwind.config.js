/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        sakhi: {
          violet: '#3A1C71',
          lavender: '#E8E2F7',
          charcoal: '#1F1F24',
          emergency: '#E63946',
          amber: '#F4A261',
          emerald: '#2A9D8F',
          surface: '#F8F9FC',
          card: '#FFFFFF',
          border: '#E2E8F0'
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
