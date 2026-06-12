import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        // Split framer-motion into its own cacheable chunk (rolldown wants the
        // function form). Routes themselves are already code-split via React.lazy.
        manualChunks(id: string) {
          if (id.includes('node_modules/framer-motion')) return 'framer-motion'
        },
      },
    },
  },
})
