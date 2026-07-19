import Nav from './nav';
import Footer from './footer';

/**
 * Layout compartilhado para páginas legais (privacidade, termos,
 * suporte). Mantém o container estreito para leitura confortável e
 * respeita o dark theme.
 */
export default function LegalLayout({
  titulo,
  subtitulo,
  children,
}: {
  titulo: string;
  subtitulo?: string;
  children: React.ReactNode;
}) {
  return (
    <>
      <Nav />
      <main className="relative">
        <section className="max-w-3xl mx-auto px-5 pt-16 pb-8">
          <p className="text-[11px] tracking-[0.28em] font-semibold text-brand-primaryLight uppercase mb-4">
            Documento oficial
          </p>
          <h1 className="font-serif text-4xl md:text-5xl text-recorpo-text leading-tight">
            {titulo}
          </h1>
          {subtitulo && (
            <p className="mt-4 text-recorpo-dim">{subtitulo}</p>
          )}
        </section>
        <section className="max-w-3xl mx-auto px-5 pb-24 text-[15px] text-recorpo-text/85 leading-relaxed">
          {children}
        </section>
      </main>
      <Footer />
    </>
  );
}
