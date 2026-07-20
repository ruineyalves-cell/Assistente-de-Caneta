'use client';

import { Canvas, useFrame } from '@react-three/fiber';
import { Environment, ContactShadows } from '@react-three/drei';
import { useRef, Suspense } from 'react';
import * as THREE from 'three';

/**
 * Caneta GLP-1 modelada geometricamente com materiais físicos (PBR).
 * clearcoat + envMap (Environment) dão o brilho característico de acabamento
 * médico. Escala reduzida em relação à versão anterior para caber inteira no
 * canvas e o giro ficar bem visível.
 */
function CanetaGLP1() {
  const grupo = useRef<THREE.Group>(null);
  const alvo = useRef({ x: 0, z: 0 });

  useFrame((state, delta) => {
    const g = grupo.current;
    if (!g) return;
    // Rotação um pouco mais rápida para o giro ficar evidente.
    g.rotation.y += delta * 0.55;
    // Parallax suave do mouse.
    alvo.current.x = -state.pointer.y * 0.15;
    alvo.current.z = state.pointer.x * 0.1;
    g.rotation.x = THREE.MathUtils.lerp(g.rotation.x, alvo.current.x, 0.05);
    g.rotation.z = THREE.MathUtils.lerp(g.rotation.z, alvo.current.z, 0.05);
    // Flutuação vertical sutil.
    g.position.y = Math.sin(state.clock.elapsedTime * 0.8) * 0.08;
  });

  return (
    <group ref={grupo} scale={0.78}>
      {/* Botão de disparo — cúpula âmbar polida no topo */}
      <mesh position={[0, 2.0, 0]} castShadow>
        <sphereGeometry args={[0.36, 48, 32]} />
        <meshPhysicalMaterial
          color="#F4CC85"
          metalness={0.6}
          roughness={0.18}
          clearcoat={1}
          clearcoatRoughness={0.05}
          emissive="#7A4E15"
          emissiveIntensity={0.18}
        />
      </mesh>

      {/* Colar do botão — aro azul emissivo */}
      <mesh position={[0, 1.72, 0]}>
        <torusGeometry args={[0.4, 0.04, 20, 64]} />
        <meshPhysicalMaterial
          color="#5FA6EF"
          emissive="#3B82C7"
          emissiveIntensity={1.2}
          metalness={0.7}
          roughness={0.18}
        />
      </mesh>

      {/* Pescoço do botão — pequeno cilindro que liga botão ao corpo */}
      <mesh position={[0, 1.55, 0]}>
        <cylinderGeometry args={[0.34, 0.4, 0.14, 48]} />
        <meshPhysicalMaterial
          color="#1B2540"
          metalness={0.7}
          roughness={0.28}
          clearcoat={0.6}
          clearcoatRoughness={0.15}
        />
      </mesh>

      {/* Corpo principal — cilindro alto escuro fosco/metálico */}
      <mesh position={[0, 0.35, 0]} castShadow>
        <cylinderGeometry args={[0.4, 0.4, 2.3, 64]} />
        <meshPhysicalMaterial
          color="#161F33"
          metalness={0.55}
          roughness={0.32}
          clearcoat={0.8}
          clearcoatRoughness={0.18}
        />
      </mesh>

      {/* Marcadores de dose — 3 anéis finos ao longo do corpo */}
      {[1.05, 0.55, 0.05, -0.45].map((y, i) => (
        <mesh key={i} position={[0, y, 0]}>
          <torusGeometry args={[0.408, 0.012, 12, 64]} />
          <meshStandardMaterial
            color="#5FA6EF"
            emissive="#3B82C7"
            emissiveIntensity={0.5}
            metalness={0.6}
            roughness={0.28}
          />
        </mesh>
      ))}

      {/* Janela de dose — retângulo âmbar minúsculo, característica visual */}
      <mesh position={[0.4, 0.75, 0]} rotation={[0, Math.PI / 2, 0]}>
        <planeGeometry args={[0.22, 0.14]} />
        <meshStandardMaterial
          color="#F4CC85"
          emissive="#E9A03C"
          emissiveIntensity={0.9}
          metalness={0.1}
          roughness={0.2}
          side={THREE.DoubleSide}
        />
      </mesh>

      {/* Anel âmbar — junção entre corpo e cápsula (assinatura visual GLP-1) */}
      <mesh position={[0, -0.82, 0]}>
        <cylinderGeometry args={[0.42, 0.42, 0.16, 64]} />
        <meshPhysicalMaterial
          color="#E9A03C"
          metalness={0.85}
          roughness={0.22}
          clearcoat={1}
          clearcoatRoughness={0.08}
          emissive="#7A4E15"
          emissiveIntensity={0.2}
        />
      </mesh>

      {/* Cápsula de vidro — transparente com transmissão real */}
      <mesh position={[0, -1.42, 0]}>
        <cylinderGeometry args={[0.34, 0.34, 0.95, 64]} />
        <meshPhysicalMaterial
          color="#E8F2FD"
          transmission={0.9}
          thickness={0.5}
          roughness={0.05}
          ior={1.45}
          metalness={0}
          transparent
          opacity={0.9}
          clearcoat={1}
          clearcoatRoughness={0.02}
        />
      </mesh>

      {/* Líquido dentro da cápsula — nível preenchendo cerca de 80% */}
      <mesh position={[0, -1.5, 0]}>
        <cylinderGeometry args={[0.28, 0.28, 0.76, 48]} />
        <meshPhysicalMaterial
          color="#4A90D9"
          emissive="#2B6CB0"
          emissiveIntensity={0.6}
          roughness={0.15}
          metalness={0.1}
          transmission={0.15}
          thickness={0.3}
        />
      </mesh>

      {/* Base — cilindro inferior escuro */}
      <mesh position={[0, -2.02, 0]}>
        <cylinderGeometry args={[0.36, 0.32, 0.34, 48]} />
        <meshPhysicalMaterial
          color="#0B1220"
          metalness={0.55}
          roughness={0.3}
          clearcoat={0.7}
        />
      </mesh>

      {/* Agulha polida — cônica bem fina */}
      <mesh position={[0, -2.32, 0]}>
        <cylinderGeometry args={[0.05, 0.01, 0.32, 24]} />
        <meshStandardMaterial
          color="#E8EEF7"
          metalness={0.95}
          roughness={0.08}
        />
      </mesh>
    </group>
  );
}

export default function Hero3D() {
  return (
    <div className="relative w-full h-[420px] md:h-[500px] flex items-center justify-center">
      {/* Halo por trás da caneta */}
      <div
        aria-hidden
        className="absolute inset-0 flex items-center justify-center pointer-events-none"
      >
        <div className="w-[300px] h-[300px] md:w-[420px] md:h-[420px] rounded-full bg-brand-primary/25 blur-[100px] animate-pulseSoft" />
      </div>

      <Canvas
        camera={{ position: [0, 0, 7], fov: 32 }}
        gl={{ antialias: true, alpha: true }}
        dpr={[1, 2]}
        shadows
      >
        {/* Iluminação principal — chave/preenchimento clássico + rim azul */}
        <ambientLight intensity={0.4} />
        <directionalLight
          position={[4, 6, 5]}
          intensity={1.5}
          color="#FFFFFF"
          castShadow
          shadow-mapSize={[1024, 1024]}
        />
        <directionalLight position={[-5, -2, -3]} intensity={0.35} color="#5FA6EF" />
        <pointLight position={[0, 0, 4]} intensity={0.5} color="#3DB5C6" />

        {/* EnvMap invisível — dá o brilho realista nos materiais PBR */}
        <Suspense fallback={null}>
          <Environment preset="city" background={false} />
          <CanetaGLP1 />
          {/* Sombra suave no chão pra dar peso */}
          <ContactShadows
            position={[0, -2.5, 0]}
            opacity={0.35}
            scale={5}
            blur={2.4}
            far={3.5}
            color="#000"
          />
        </Suspense>
      </Canvas>
    </div>
  );
}
