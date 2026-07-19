'use client';

import { motion } from 'framer-motion';

/**
 * Fade + rise ao entrar no viewport. Usado por seções longas da
 * landing pra dar ritmo sem depender de bibliotecas externas.
 */
export default function RevealOnScroll({
  children,
  delay = 0,
}: {
  children: React.ReactNode;
  delay?: number;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      whileInView={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.8, delay, ease: [0.2, 0.7, 0.2, 1] }}
      viewport={{ once: true, amount: 0.2 }}
    >
      {children}
    </motion.div>
  );
}
