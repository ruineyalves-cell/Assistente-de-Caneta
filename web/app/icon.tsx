import { ImageResponse } from 'next/og';

export const runtime = 'edge';
export const size = { width: 512, height: 512 };
export const contentType = 'image/png';

export default function Icon() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          background: 'linear-gradient(135deg, #4A90D9 0%, #2B6CB0 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 320,
          fontFamily: 'serif',
          color: '#F1F5FB',
          fontWeight: 500,
        }}
      >
        R
      </div>
    ),
    size,
  );
}
