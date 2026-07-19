'use client';

import { motion } from 'framer-motion';

const EIXOS = [
  {
    nome: 'Refeição',
    emoji: '🍊',
    resumo: 'Reconhecimento por foto, macros e sugestões pós-refeição.',
    gradient: 'bg-refeicao-gradient',
    detalhe:
      'A IA identifica o prato, estima a proteína e sugere ajustes que respeitam sua saciedade GLP-1.',
  },
  {
    nome: 'Água',
    emoji: '💧',
    resumo: 'Widget rápido, meta pelo peso e alertas na hora certa.',
    gradient: 'bg-agua-gradient',
    detalhe:
      'Meta calculada pelo seu peso, com +250 e +500 direto do home screen. Sem sede acumulada.',
  },
  {
    nome: 'Peso',
    emoji: '⚖️',
    resumo: 'Gráfico honesto e evolução real, sem promessa milagrosa.',
    gradient: 'bg-peso-gradient',
    detalhe:
      'Kg por semana, comparação com o registro anterior e histórico organizado para levar ao médico.',
  },
  {
    nome: 'Sintomas',
    emoji: '🩺',
    resumo: '15 sintomas curados de bulas Anvisa, com intensidade.',
    gradient: 'bg-sintomas-gradient',
    detalhe:
      'Farmacovigilância séria — o app aprendeu com bulas oficiais e destaca o que merece conversa com o médico.',
  },
];

const container = {
  hidden: {},
  show: {
    transition: { staggerChildren: 0.09 },
  },
};

const item = {
  hidden: { opacity: 0, y: 24 },
  show: { opacity: 1, y: 0, transition: { duration: 0.7, ease: [0.2, 0.7, 0.2, 1] as const } },
};

export default function EixoCards() {
  return (
    <motion.div
      className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4"
      variants={container}
      initial="hidden"
      whileInView="show"
      viewport={{ once: true, amount: 0.25 }}
    >
      {EIXOS.map((e) => (
        <motion.div
          key={e.nome}
          variants={item}
          whileHover={{ y: -6 }}
          transition={{ type: 'spring', stiffness: 260, damping: 22 }}
          className="group relative rounded-2xl border border-white/[0.08] bg-recorpo-surface/70 backdrop-blur-md p-6 overflow-hidden"
        >
          {/* Glow por trás no hover */}
          <div
            aria-hidden
            className={`absolute -top-16 -right-16 w-40 h-40 rounded-full ${e.gradient} opacity-30 blur-2xl transition-opacity group-hover:opacity-50`}
          />
          <div
            className={`relative w-12 h-12 rounded-xl ${e.gradient} flex items-center justify-center text-2xl mb-4 shadow-glowSoft`}
          >
            {e.emoji}
          </div>
          <h3 className="font-serif text-2xl text-recorpo-text mb-2">
            {e.nome}
          </h3>
          <p className="text-recorpo-dim text-sm leading-relaxed">
            {e.resumo}
          </p>
          <p className="mt-4 text-xs text-recorpo-muted leading-relaxed">
            {e.detalhe}
          </p>
        </motion.div>
      ))}
    </motion.div>
  );
}
