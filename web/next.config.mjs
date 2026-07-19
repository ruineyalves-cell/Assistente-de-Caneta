/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  transpilePackages: ['three'],
  images: {
    formats: ['image/avif', 'image/webp'],
  },
  env: {
    NEXT_PUBLIC_API_BASE:
      process.env.NEXT_PUBLIC_API_BASE ??
      'https://assistente-caneta-backend-tkl7.onrender.com',
  },
};

export default nextConfig;
