import { ImageResponse } from 'next/og';

export const runtime = 'edge';
export const alt = 'Recorpo — Assistente de Caneta GLP-1';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          background:
            'radial-gradient(ellipse at top left, #1A2540 0%, #0B111A 55%, #06090F 100%)',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          padding: '72px 80px',
          fontFamily: 'sans-serif',
          color: '#F1F5FB',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
          <div
            style={{
              width: 64,
              height: 64,
              borderRadius: 32,
              background: 'linear-gradient(135deg, #4A90D9 0%, #2B6CB0 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 40,
              fontFamily: 'serif',
              fontWeight: 500,
            }}
          >
            R
          </div>
          <div style={{ fontSize: 32, letterSpacing: 2, opacity: 0.85 }}>
            RECORPO
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          <div
            style={{
              fontSize: 26,
              letterSpacing: 8,
              textTransform: 'uppercase',
              color: '#7FB0E5',
              fontWeight: 600,
            }}
          >
            Assistente de Caneta GLP-1
          </div>
          <div
            style={{
              fontSize: 76,
              fontFamily: 'serif',
              lineHeight: 1.05,
              maxWidth: 980,
              fontWeight: 400,
            }}
          >
            O seu tratamento merece acompanhamento próprio.
          </div>
          <div style={{ fontSize: 28, opacity: 0.7, marginTop: 10 }}>
            Registre · Acompanhe · Compartilhe com quem cuida de você
          </div>
        </div>

        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            fontSize: 22,
            opacity: 0.55,
          }}
        >
          <div>recorpo.com.br</div>
          <div>Disponível na Play Store</div>
        </div>
      </div>
    ),
    size,
  );
}
