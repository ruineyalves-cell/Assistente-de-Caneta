export default function LogoMark({ className = '' }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 48 48"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden
    >
      <defs>
        <linearGradient id="rc-g" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#4A90D9" />
          <stop offset="1" stopColor="#2B6CB0" />
        </linearGradient>
      </defs>
      <circle cx="24" cy="24" r="22" fill="url(#rc-g)" />
      <path
        d="M18 14v20M18 14h8a5 5 0 010 10h-8m8 0l6 10"
        stroke="#F1F5FB"
        strokeWidth="3"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
