'use client';

import { useCallback, useEffect, useRef, useState } from 'react';

/**
 * Captura de foto no navegador com 2 modos:
 *
 *   1. Câmera ao vivo via getUserMedia (facingMode 'environment' pra
 *      pegar câmera traseira no celular).
 *   2. Upload de arquivo (fallback quando getUserMedia falha OU
 *      quando o user prefere galeria).
 *
 * Após capturar/selecionar, aplica compressão client-side:
 *   - Resize pro lado maior = 1280px (mantém aspecto)
 *   - JPEG q=0.8
 *   - Retira EXIF (privacy — remove GPS/câmera)
 *
 * Devolve base64 sem prefixo `data:image/jpeg;base64,` porque o
 * backend `iaController` só quer os bytes.
 */

type Props = {
  onCaptura: (imagemBase64: string) => void;
  onCancelar: () => void;
  hint?: string;
};

const MAX_LADO_PX = 1280;
const QUALIDADE = 0.8;

export function CameraCapture({ onCaptura, onCancelar, hint }: Props) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const [modo, setModo] = useState<'iniciando' | 'ao-vivo' | 'fallback' | 'preview'>(
    'iniciando'
  );
  const [erro, setErro] = useState<string | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [base64Cache, setBase64Cache] = useState<string | null>(null);

  const [motivoFallback, setMotivoFallback] = useState<string | null>(null);

  // Boot: tenta abrir câmera. Se falhar, guarda o motivo específico
  // pra mostrar hint útil ao user (permissão negada vs sem câmera vs
  // HTTP não-secure).
  useEffect(() => {
    let cancelado = false;
    (async () => {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices?.getUserMedia) {
        setMotivoFallback(
          'Seu navegador não suporta captura direta de câmera. Use "Da galeria" abaixo.'
        );
        setModo('fallback');
        return;
      }
      if (typeof window !== 'undefined' && window.location.protocol !== 'https:' && window.location.hostname !== 'localhost') {
        setMotivoFallback(
          'Câmera exige conexão segura (HTTPS). Envie foto da galeria.'
        );
        setModo('fallback');
        return;
      }
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: {
            facingMode: { ideal: 'environment' },
            width: { ideal: 1920 },
            height: { ideal: 1080 },
          },
          audio: false,
        });
        if (cancelado) {
          stream.getTracks().forEach((t) => t.stop());
          return;
        }
        streamRef.current = stream;
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
        }
        setModo('ao-vivo');
      } catch (e) {
        const err = e as DOMException;
        console.warn('Câmera indisponível:', err.name, err.message);
        // Mensagens específicas por tipo de erro — user consegue agir.
        let motivo: string;
        switch (err.name) {
          case 'NotAllowedError':
          case 'PermissionDeniedError':
            motivo =
              'Você negou o acesso à câmera. Toque no cadeado ao lado do endereço e permita "Câmera" pra tentar de novo, ou envie da galeria.';
            break;
          case 'NotFoundError':
          case 'DevicesNotFoundError':
            motivo =
              'Nenhuma câmera encontrada neste aparelho. Envie foto da galeria.';
            break;
          case 'NotReadableError':
          case 'TrackStartError':
            motivo =
              'Câmera ocupada por outro app. Feche apps de câmera/vídeo e tente de novo, ou envie da galeria.';
            break;
          case 'OverconstrainedError':
            motivo =
              'Seu aparelho não tem câmera traseira. Enviando da galeria funciona.';
            break;
          default:
            motivo = `Não consegui abrir a câmera (${err.name || 'erro'}). Envie da galeria.`;
        }
        setMotivoFallback(motivo);
        setModo('fallback');
      }
    })();
    return () => {
      cancelado = true;
      streamRef.current?.getTracks().forEach((t) => t.stop());
      if (previewUrl) URL.revokeObjectURL(previewUrl);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /** Redimensiona imagem pro lado maior de MAX_LADO_PX e retorna base64. */
  const comprimir = useCallback(
    async (fonte: HTMLVideoElement | HTMLImageElement): Promise<string> => {
      const w =
        fonte instanceof HTMLVideoElement ? fonte.videoWidth : fonte.naturalWidth;
      const h =
        fonte instanceof HTMLVideoElement ? fonte.videoHeight : fonte.naturalHeight;
      const escala = Math.min(1, MAX_LADO_PX / Math.max(w, h));
      const destW = Math.round(w * escala);
      const destH = Math.round(h * escala);
      const canvas = canvasRef.current ?? document.createElement('canvas');
      canvas.width = destW;
      canvas.height = destH;
      const ctx = canvas.getContext('2d');
      if (!ctx) throw new Error('Canvas não suportado');
      ctx.drawImage(fonte, 0, 0, destW, destH);
      const dataUrl = canvas.toDataURL('image/jpeg', QUALIDADE);
      // strip prefix `data:image/jpeg;base64,`
      const marker = 'base64,';
      const idx = dataUrl.indexOf(marker);
      return idx >= 0 ? dataUrl.slice(idx + marker.length) : dataUrl;
    },
    []
  );

  async function tirarFoto() {
    if (!videoRef.current) return;
    try {
      const b64 = await comprimir(videoRef.current);
      setBase64Cache(b64);
      // Preview a partir do dataUrl
      setPreviewUrl(`data:image/jpeg;base64,${b64}`);
      setModo('preview');
      // Para o stream — libera câmera.
      streamRef.current?.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
    } catch (e) {
      setErro((e as Error).message ?? 'Falha ao capturar');
    }
  }

  function retomar() {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setPreviewUrl(null);
    setBase64Cache(null);
    // Reinicia câmera
    setModo('iniciando');
    (async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: { ideal: 'environment' } },
          audio: false,
        });
        streamRef.current = stream;
        if (videoRef.current) videoRef.current.srcObject = stream;
        setModo('ao-vivo');
      } catch {
        setModo('fallback');
      }
    })();
  }

  async function aoSelecionarArquivo(e: React.ChangeEvent<HTMLInputElement>) {
    const arquivo = e.target.files?.[0];
    if (!arquivo) return;
    if (!arquivo.type.startsWith('image/')) {
      setErro('Selecione uma imagem (JPG, PNG).');
      return;
    }
    try {
      const url = URL.createObjectURL(arquivo);
      const img = new Image();
      img.crossOrigin = 'anonymous';
      await new Promise<void>((resolve, reject) => {
        img.onload = () => resolve();
        img.onerror = () => reject(new Error('Imagem inválida'));
        img.src = url;
      });
      const b64 = await comprimir(img);
      URL.revokeObjectURL(url);
      setBase64Cache(b64);
      setPreviewUrl(`data:image/jpeg;base64,${b64}`);
      setModo('preview');
    } catch (err) {
      setErro((err as Error).message ?? 'Falha ao processar imagem');
    }
  }

  function confirmar() {
    if (base64Cache) onCaptura(base64Cache);
  }

  return (
    <div className="space-y-3">
      {hint && (
        <p className="rounded-lg bg-recorpo-surfaceHi p-3 text-sm text-recorpo-text">
          {hint}
        </p>
      )}

      {modo === 'iniciando' && (
        <div className="grid aspect-video place-items-center rounded-xl border border-recorpo-border bg-recorpo-bg text-sm text-recorpo-dim">
          Iniciando câmera…
        </div>
      )}

      {modo === 'ao-vivo' && (
        <>
          <video
            ref={videoRef}
            autoPlay
            playsInline
            muted
            className="w-full rounded-xl border border-recorpo-border bg-black"
          />
          <div className="flex gap-2">
            <button
              onClick={tirarFoto}
              className="flex-1 rounded-lg bg-brand-primary py-3 font-medium text-white hover:bg-brand-primaryDark"
            >
              📷 Tirar foto
            </button>
            <label className="flex-1 cursor-pointer rounded-lg border border-recorpo-border py-3 text-center text-sm text-recorpo-text hover:bg-recorpo-surfaceHi">
              Da galeria
              <input
                type="file"
                accept="image/*"
                onChange={aoSelecionarArquivo}
                className="hidden"
              />
            </label>
          </div>
        </>
      )}

      {modo === 'fallback' && (
        <div className="rounded-xl border border-recorpo-border bg-recorpo-bg p-6 text-center">
          <span className="text-4xl" aria-hidden>
            📷
          </span>
          <p className="mt-3 text-sm text-recorpo-text">
            {motivoFallback ?? 'Câmera indisponível.'}
          </p>
          <label className="mt-4 inline-flex cursor-pointer rounded-lg bg-brand-primary px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-primaryDark">
            📁 Escolher imagem
            <input
              type="file"
              accept="image/*"
              capture="environment"
              onChange={aoSelecionarArquivo}
              className="hidden"
            />
          </label>
          <p className="mt-3 text-xs text-recorpo-muted">
            No celular, o botão acima abre a câmera ou a galeria (você escolhe).
          </p>
        </div>
      )}

      {modo === 'preview' && previewUrl && (
        <>
          <img
            src={previewUrl}
            alt="Prévia da foto"
            className="w-full rounded-xl border border-recorpo-border"
          />
          <div className="flex gap-2">
            <button
              onClick={retomar}
              className="flex-1 rounded-lg border border-recorpo-border py-3 text-sm text-recorpo-text hover:bg-recorpo-surfaceHi"
            >
              Refazer
            </button>
            <button
              onClick={confirmar}
              className="flex-1 rounded-lg bg-brand-primary py-3 font-medium text-white hover:bg-brand-primaryDark"
            >
              Analisar com IA
            </button>
          </div>
        </>
      )}

      {erro && (
        <p className="rounded-lg border border-eixo-sintomas/40 bg-eixo-sintomas/10 px-3 py-2 text-sm text-eixo-sintomas">
          {erro}
        </p>
      )}

      <button
        onClick={onCancelar}
        className="w-full rounded-lg py-2 text-xs text-recorpo-dim hover:text-recorpo-text"
      >
        Cancelar
      </button>

      {/* Canvas escondido — só usado pra compressão */}
      <canvas ref={canvasRef} className="hidden" aria-hidden />
    </div>
  );
}
