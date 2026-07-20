import Link from 'next/link';
import LogoMark from './logo-mark';

export default function Footer() {
  return (
    <footer className="mt-32 border-t border-white/[0.06] bg-recorpo-surface/40">
      <div className="max-w-6xl mx-auto px-5 py-14 grid gap-10 md:grid-cols-4 text-sm text-recorpo-dim">
        <div className="md:col-span-2">
          <div className="flex items-center gap-2.5">
            <LogoMark className="w-8 h-8" />
            <span className="font-serif text-2xl text-recorpo-text">
              Recorpo
            </span>
          </div>
          <p className="mt-4 max-w-sm text-recorpo-dim leading-relaxed">
            Assistente de Caneta — companheiro de quem faz tratamento com GLP-1.
            Feito para acompanhar sua jornada e conversar com quem cuida de você.
          </p>
        </div>

        <div>
          <h4 className="text-recorpo-text text-xs font-semibold tracking-[0.15em] uppercase mb-3">
            Produto
          </h4>
          <ul className="space-y-2.5">
            <li><Link href="/#recursos" className="hover:text-recorpo-text transition-colors">Recursos</Link></li>
            <li><Link href="/#baixar" className="hover:text-recorpo-text transition-colors">Baixar</Link></li>
            <li><Link href="/portal/login" className="hover:text-recorpo-text transition-colors">Portal médico</Link></li>
            <li><Link href="/suporte" className="hover:text-recorpo-text transition-colors">Suporte</Link></li>
          </ul>
        </div>

        <div>
          <h4 className="text-recorpo-text text-xs font-semibold tracking-[0.15em] uppercase mb-3">
            Legal
          </h4>
          <ul className="space-y-2.5">
            <li><Link href="/privacidade" className="hover:text-recorpo-text transition-colors">Privacidade</Link></li>
            <li><Link href="/termos" className="hover:text-recorpo-text transition-colors">Termos de uso</Link></li>
            <li>
              <a
                href="mailto:recorpoapp@gmail.com"
                className="hover:text-recorpo-text transition-colors"
              >
                recorpoapp@gmail.com
              </a>
            </li>
          </ul>
        </div>
      </div>
      <div className="border-t border-white/[0.04] py-6 text-xs text-recorpo-muted text-center">
        © {new Date().getFullYear()} Recorpo · Ferramenta educacional. Não fornece
        diagnóstico e não substitui orientação médica.
      </div>
    </footer>
  );
}
