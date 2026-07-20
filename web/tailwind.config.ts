import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Espelha lib/utils/theme.dart do app. Fonte única de verdade
        // dos tokens — reaproveita pra que o site "sinta" o produto.
        brand: {
          primary: '#2B6CB0',
          primaryDark: '#1E4E85',
          primaryLight: '#4A90D9',
        },
        eixo: {
          refeicao: '#E27D3F',
          refeicaoDark: '#B35F28',
          agua: '#3DB5C6',
          aguaDark: '#287E8B',
          peso: '#4FBFA8',
          pesoDark: '#2E8A78',
          sintomas: '#E76F51',
          sintomasDark: '#AB4E38',
          streak: '#E9A03C',
          streakDark: '#AF7625',
          movimento: '#7C6BC7',
          movimentoDark: '#554791',
        },
        // Backgrounds do brand.
        recorpo: {
          bg: '#0B1220',
          surface: '#131C2E',
          surfaceHi: '#1A2540',
          border: 'rgba(255,255,255,0.08)',
          text: '#F1F5FB',
          dim: '#9AA6B8',
          muted: '#6B7893',
        },
      },
      fontFamily: {
        sans: ['var(--font-inter)', 'system-ui', 'sans-serif'],
        serif: ['var(--font-instrument)', 'Georgia', 'serif'],
      },
      boxShadow: {
        glow: '0 0 60px -12px rgba(74,144,217,0.55)',
        glowSoft: '0 0 90px -20px rgba(74,144,217,0.4)',
      },
      backgroundImage: {
        'primary-gradient':
          'linear-gradient(135deg, #4A90D9 0%, #2B6CB0 100%)',
        'refeicao-gradient':
          'linear-gradient(135deg, #E27D3F 0%, #B35F28 100%)',
        'agua-gradient':
          'linear-gradient(135deg, #3DB5C6 0%, #287E8B 100%)',
        'peso-gradient':
          'linear-gradient(135deg, #4FBFA8 0%, #2E8A78 100%)',
        'sintomas-gradient':
          'linear-gradient(135deg, #E76F51 0%, #AB4E38 100%)',
      },
      keyframes: {
        drift: {
          '0%, 100%': { transform: 'translate(0,0) scale(1)' },
          '33%': { transform: 'translate(30px,20px) scale(1.05)' },
          '66%': { transform: 'translate(-24px,12px) scale(0.95)' },
        },
        rise: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '0.6' },
          '50%': { opacity: '1' },
        },
        'hero-float': {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-14px)' },
        },
        'hero-floatSlow': {
          '0%, 100%': { transform: 'rotate(-4deg) translateY(0)' },
          '50%': { transform: 'rotate(-4deg) translateY(-10px)' },
        },
        'hero-floatFast': {
          '0%, 100%': { transform: 'rotate(5deg) translateY(0)' },
          '50%': { transform: 'rotate(5deg) translateY(-8px)' },
        },
        'hero-draw': {
          '0%': { strokeDashoffset: '290' },
          '60%, 100%': { strokeDashoffset: '0' },
        },
        'hero-water': {
          '0%, 100%': { strokeDashoffset: '30' },
          '50%': { strokeDashoffset: '15' },
        },
        'hero-waterRing': {
          '0%, 100%': { strokeDashoffset: '55' },
          '50%': { strokeDashoffset: '30' },
        },
      },
      animation: {
        drift: 'drift 22s ease-in-out infinite',
        rise: 'rise 1s cubic-bezier(0.2,0.7,0.2,1) both',
        pulseSoft: 'pulseSoft 4s ease-in-out infinite',
        'hero-float': 'hero-float 6s ease-in-out infinite',
        'hero-floatSlow': 'hero-floatSlow 8s ease-in-out infinite',
        'hero-floatFast': 'hero-floatFast 5s ease-in-out infinite',
        'hero-draw': 'hero-draw 3.2s ease-out infinite',
        'hero-water': 'hero-water 5s ease-in-out infinite',
        'hero-waterRing': 'hero-waterRing 6s ease-in-out infinite',
      },
    },
  },
  plugins: [],
};
export default config;
