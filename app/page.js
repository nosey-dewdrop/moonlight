"use client";

import { useEffect, useState } from "react";

function getMoonPhase() {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1;
  const day = now.getDate();

  let c = 0, e = 0, jd = 0, b = 0;
  if (month < 3) {
    c = 365.25 * (year - 1);
    e = 30.6001 * (month + 13);
  } else {
    c = 365.25 * year;
    e = 30.6001 * (month + 1);
  }
  jd = c + e + day - 694039.09;
  jd /= 29.5305882;
  b = parseInt(jd);
  jd -= b;
  b = Math.round(jd * 8);
  if (b >= 8) b = 0;

  const phases = [
    { emoji: "🌑", name: "Yeni Ay" },
    { emoji: "🌒", name: "Hilal (Büyüyen)" },
    { emoji: "🌓", name: "İlk Dördün" },
    { emoji: "🌔", name: "Şişkin Ay (Büyüyen)" },
    { emoji: "🌕", name: "Dolunay" },
    { emoji: "🌖", name: "Şişkin Ay (Küçülen)" },
    { emoji: "🌗", name: "Son Dördün" },
    { emoji: "🌘", name: "Hilal (Küçülen)" },
  ];
  return phases[b];
}

function Stars() {
  const [stars, setStars] = useState([]);

  useEffect(() => {
    const generated = Array.from({ length: 120 }, (_, i) => ({
      id: i,
      x: Math.random() * 100,
      y: Math.random() * 100,
      size: Math.random() * 2.5 + 1,
      delay: Math.random() * 4,
      duration: Math.random() * 3 + 2,
    }));
    setStars(generated);
  }, []);

  return (
    <div className="fixed inset-0 pointer-events-none">
      {stars.map((star) => (
        <div
          key={star.id}
          className="absolute rounded-full"
          style={{
            left: `${star.x}%`,
            top: `${star.y}%`,
            width: `${star.size}px`,
            height: `${star.size}px`,
            backgroundColor: "#fffbe6",
            animation: `twinkle ${star.duration}s ${star.delay}s infinite`,
          }}
        />
      ))}
    </div>
  );
}

const NAV_ITEMS = [
  { label: "ay takvimi", href: "/takvim" },
  { label: "astroloji", href: "/astroloji" },
  { label: "tarot", href: "/tarot" },
  { label: "sözlük", href: "/sozluk" },
];

export default function Home() {
  const moon = getMoonPhase();

  return (
    <main className="relative min-h-screen flex flex-col items-center justify-center px-4">
      <Stars />

      <div className="relative z-10 flex flex-col items-center gap-8">
        {/* Moon */}
        <div
          className="text-7xl sm:text-8xl"
          style={{ animation: "float 4s ease-in-out infinite" }}
        >
          {moon.emoji}
        </div>

        {/* Title */}
        <h1
          className="text-2xl sm:text-3xl tracking-widest text-center"
          style={{ fontFamily: "var(--font-pixel)", color: "var(--accent)" }}
        >
          moonlight
        </h1>

        {/* Moon phase */}
        <p className="text-xl sm:text-2xl opacity-70" style={{ fontFamily: "var(--font-vt323)" }}>
          {moon.name}
        </p>

        {/* Navigation */}
        <nav className="flex flex-wrap justify-center gap-4 mt-6">
          {NAV_ITEMS.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="border border-[var(--accent)] px-4 py-2 text-sm sm:text-base hover:bg-[var(--accent)] hover:text-[var(--background)] transition-colors duration-200"
              style={{ fontFamily: "var(--font-pixel)", fontSize: "10px" }}
            >
              {item.label}
            </a>
          ))}
        </nav>
      </div>
    </main>
  );
}
