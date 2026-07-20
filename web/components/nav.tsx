import Link from 'next/link';
import LogoMark from './logo-mark';

export default function Nav() {
  return (
    <header className="sticky top-0 z-40 backdrop-blur-xl bg-recorpo-bg/70 border-b border-white/[0.06]">
      <div className="max-w-6xl mx-auto px-5 h-16 flex items-center justify-between gap-6">
        <Link
          href="/"
          className="flex items-center gap-2.5 group"
          aria-label="Recorpo"
        >
          <LogoMark className="w-7 h-7" />
          <span className="font-serif text-xl tracking-wide text-recorpo-text group-hover:text-brand-primaryLight transition-colors">
            Recorpo
          </span>
        </Link>

        <nav className="hidden md:flex items-center gap-7 text-sm text-recorpo-dim">
          <Link href="/#app" className="hover:text-recorpo-text transition-colors">
            O app
          </Link>
          <Link href="/#recursos" className="hover:text-recorpo-text transition-colors">
            Recursos
          </Link>
          <Link href="/#baixar" className="hover:text-recorpo-text transition-colors">
            Baixar
          </Link>
          <Link href="/suporte" className="hover:text-recorpo-text transition-colors">
            Suporte
          </Link>
          <Link
            href="/portal/login"
            className="hover:text-recorpo-text transition-colors"
          >
            Portal médico
          </Link>
        </nav>

        <Link
          href="/#baixar"
          className="inline-flex items-center gap-2 text-sm font-semibold px-4 py-2 rounded-full bg-primary-gradient text-white shadow-glowSoft hover:brightness-110 transition-all"
        >
          Baixe grátis
        </Link>
      </div>
    </header>
  );
}
