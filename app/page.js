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

function seededRandom(seed) {
  let s = seed;
  return function () {
    s = (s * 16807 + 0) % 2147483647;
    return s / 2147483647;
  };
}

function generateStarShadows(count, seed) {
  const rand = seededRandom(seed);
  const shadows = [];
  for (let i = 0; i < count; i++) {
    const x = Math.round(rand() * 2000);
    const y = Math.round(rand() * 2000);
    shadows.push(`${x}px ${y}px #fffbe6`);
  }
  return shadows.join(",");
}

const NAV_ITEMS = [
  { label: "ay takvimi", href: "/takvim" },
  { label: "astroloji", href: "/astroloji" },
  { label: "tarot", href: "/tarot" },
  { label: "sözlük", href: "/sozluk" },
];

export default function Home() {
  const moon = getMoonPhase();
  const smallStars = generateStarShadows(80, 111);
  const mediumStars = generateStarShadows(30, 222);
  const largeStars = generateStarShadows(10, 333);

  return (
    <main className="relative min-h-screen flex flex-col items-center justify-center px-4">
      {/* Stars - pure CSS, zero JS on client */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <div
          className="absolute"
          style={{
            width: "1px",
            height: "1px",
            boxShadow: smallStars,
            animation: "twinkle 4s infinite",
          }}
        />
        <div
          className="absolute"
          style={{
            width: "2px",
            height: "2px",
            boxShadow: mediumStars,
            animation: "twinkle 3s 1s infinite",
          }}
        />
        <div
          className="absolute"
          style={{
            width: "3px",
            height: "3px",
            boxShadow: largeStars,
            animation: "twinkle 5s 2s infinite",
          }}
        />
      </div>

      <div className="relative z-10 flex flex-col items-center gap-8">
        <div
          className="text-7xl sm:text-8xl"
          style={{ animation: "float 4s ease-in-out infinite" }}
        >
          {moon.emoji}
        </div>

        <h1
          className="text-2xl sm:text-3xl tracking-widest text-center"
          style={{ fontFamily: "var(--font-pixel)", color: "var(--accent)" }}
        >
          moonlight
        </h1>

        <p className="text-xl sm:text-2xl opacity-70" style={{ fontFamily: "var(--font-vt323)" }}>
          {moon.name}
        </p>

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
