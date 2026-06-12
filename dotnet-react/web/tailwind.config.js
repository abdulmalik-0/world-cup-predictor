/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        navy: '#0A1E3C',
        gold: '#E9B84A',
        fifaRed: '#E23B5A',
        fifaBlue: '#2766FF',
        ink: '#050505',
        card: '#0B1118',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['"Bebas Neue"', 'Inter', 'system-ui', 'sans-serif'],
      },
      animation: {
        shimmer: 'shimmer 2.4s linear infinite',
        float: 'float 4s ease-in-out infinite',
      },
      keyframes: {
        shimmer: {
          '0%':   { transform: 'translateX(-120%)' },
          '100%': { transform: 'translateX(120%)' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%':      { transform: 'translateY(-6px)' },
        },
      },
    },
  },
  plugins: [],
}
