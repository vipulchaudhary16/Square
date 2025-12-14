import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'


export default defineConfig({
  plugins: [react()],
  server: {
    allowedHosts: [
      '9b59011b78dc.ngrok-free.app'
    ],
    host: true,
  }
})
