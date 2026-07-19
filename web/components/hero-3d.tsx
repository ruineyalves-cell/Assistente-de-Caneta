'use client';

import { Canvas, useFrame } from '@react-three/fiber';
import { useRef, Suspense } from 'react';
import * as THREE from 'three';

/**
 * Caneta GLP-1 modelada geometricamente (sem asset externo).
 * Corpo escuro fosco + cápsula translúcida com líquido azul-clínico +
 * botão-dose âmbar + agulha polida. Gira devagar continuamente e
 * ganha um leve tilt de acordo com o mouse (efeito pilotável).
 */
function CanetaGLP1() {
  const grupo = useRef<THREE.Group>(null);
  // Guardamos a rotação-alvo em uma ref pra não misturar com o Float
  // do Drei (esse tipo de duplo-write é o erro clássico).
  const alvo = useRef({ x: 0, z: 0 });

  useFrame((state, delta) => {
    const g = grupo.current;
    if (!g) return;
    // Rotação constante ao redor do eixo Y.
    g.rotation.y += delta * 0.35;
    // Parallax suave a partir do mouse (state.pointer é [-1..1]).
    alvo.current.x = -state.pointer.y * 0.18;
    alvo.current.z = state.pointer.x * 0.12;
    g.rotation.x = THREE.MathUtils.lerp(g.rotation.x, alvo.current.x, 0.06);
    g.rotation.z = THREE.MathUtils.lerp(g.rotation.z, alvo.current.z, 0.06);
    // Flutuação vertical sutil, autoral (não dependemos do <Float>).
    g.position.y = Math.sin(state.clock.elapsedTime * 0.9) * 0.12;
  });

  return (
    <group ref={grupo}>
      {/* Corpo principal — cilindro alongado escuro */}
      <mesh position={[0, 0.2, 0]}>
        <cylinderGeometry args={[0.42, 0.42, 3.2, 48]} />
        <meshStandardMaterial
          color="#131C2E"
          metalness={0.45}
          roughness={0.35}
        />
      </mesh>

      {/* Anel de junção — âmbar sutil no meio */}
      <mesh position={[0, -0.35, 0]}>
        <cylinderGeometry args={[0.44, 0.44, 0.18, 48]} />
        <meshStandardMaterial
          color="#E9A03C"
          metalness={0.85}
          roughness={0.28}
          emissive="#8A5E1F"
          emissiveIntensity={0.25}
        />
      </mesh>

      {/* Cápsula de vidro semitransparente */}
      <mesh position={[0, -1.05, 0]}>
        <cylinderGeometry args={[0.34, 0.34, 1.1, 48]} />
        <meshStandardMaterial
          color="#4A90D9"
          transparent
          opacity={0.35}
          metalness={0.2}
          roughness={0.15}
        />
      </mesh>

      {/* Miolo de líquido brilhante dentro da cápsula */}
      <mesh position={[0, -1.05, 0]}>
        <cylinderGeometry args={[0.22, 0.22, 0.95, 32]} />
        <meshStandardMaterial
          color="#4A90D9"
          emissive="#2B6CB0"
          emissiveIntensity={0.7}
          roughness={0.2}
          metalness={0.1}
        />
      </mesh>

      {/* Base — parte inferior escura */}
      <mesh position={[0, -1.75, 0]}>
        <cylinderGeometry args={[0.36, 0.36, 0.36, 48]} />
        <meshStandardMaterial color="#0B1220" metalness={0.4} roughness={0.4} />
      </mesh>

      {/* Agulha polida */}
      <mesh position={[0, -2.05, 0]}>
        <cylinderGeometry args={[0.06, 0.02, 0.28, 24]} />
        <meshStandardMaterial
          color="#E1EAF5"
          metalness={0.95}
          roughness={0.12}
        />
      </mesh>

      {/* Botão de disparo — parte superior âmbar arredondada */}
      <mesh position={[0, 2.05, 0]}>
        <sphereGeometry args={[0.38, 32, 24]} />
        <meshStandardMaterial
          color="#F1C87C"
          metalness={0.65}
          roughness={0.28}
          emissive="#8A5E1F"
          emissiveIntensity={0.35}
        />
      </mesh>

      {/* Anel indicador do botão */}
      <mesh position={[0, 1.78, 0]}>
        <torusGeometry args={[0.42, 0.05, 16, 48]} />
        <meshStandardMaterial
          color="#4A90D9"
          emissive="#2B6CB0"
          emissiveIntensity={0.8}
          metalness={0.7}
          roughness={0.2}
        />
      </mesh>

      {/* Marcadores de dose — 3 anéis finos no corpo */}
      {[0.9, 0.5, 0.1].map((y, i) => (
        <mesh key={i} position={[0, y, 0]}>
          <torusGeometry args={[0.425, 0.012, 12, 48]} />
          <meshStandardMaterial
            color="#4A90D9"
            emissive="#4A90D9"
            emissiveIntensity={0.4}
            metalness={0.6}
            roughness={0.3}
          />
        </mesh>
      ))}
    </group>
  );
}

export default function Hero3D() {
  return (
    <div className="relative w-full h-[520px] md:h-[620px] flex items-center justify-center">
      {/* Halo por trás da caneta */}
      <div
        aria-hidden
        className="absolute inset-0 flex items-center justify-center pointer-events-none"
      >
        <div className="w-[380px] h-[380px] md:w-[520px] md:h-[520px] rounded-full bg-brand-primary/30 blur-[100px] animate-pulseSoft" />
      </div>

      <Canvas
        camera={{ position: [0, 0, 6.5], fov: 34 }}
        gl={{ antialias: true, alpha: true }}
        dpr={[1, 2]}
      >
        <ambientLight intensity={0.55} />
        <directionalLight
          position={[3, 5, 4]}
          intensity={1.4}
          color="#F1F5FB"
        />
        <directionalLight position={[-4, -2, -3]} intensity={0.5} color="#4A90D9" />
        <pointLight position={[0, 0, 3]} intensity={0.7} color="#3DB5C6" />

        <Suspense fallback={null}>
          <CanetaGLP1 />
        </Suspense>
      </Canvas>
    </div>
  );
}
