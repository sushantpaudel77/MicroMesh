const STATS = [
  { value: '500+', label: 'Products' },
  { value: '4.9★', label: 'Avg Rating' },
  { value: '24h', label: 'Dispatch' },
];

function Hero({ user, onSignInClick }) {
  return (
    <section className="relative overflow-hidden min-h-[92vh] flex items-center bg-black">
      {/* Background image */}
      <div
        className="absolute inset-0 bg-cover bg-center"
        style={{
          backgroundImage: "url('/images/hero-bg.webp')",
          filter: 'brightness(0.35)',
        }}
      />

      {/* Subtle grain overlay */}
      <div
        className="absolute inset-0 bg-cover bg-center"
        style={{
          backgroundImage: "url('/images/hero-bg.webp')",
          backgroundColor: '#1a1410', 
          filter: 'brightness(0.35)',
          willChange: 'opacity',
        }}
      />

      {/* Content */}
      <div className="relative w-full max-w-7xl mx-auto px-8 pt-20 pb-40">
        <div className="max-w-3xl">
          {/* Headline */}
          <h1 className="text-6xl md:text-7xl lg:text-8xl font-light text-white leading-none tracking-tight mb-6">
            Curated for
            <br />
            <span className="font-normal italic text-neutral-300">modern living</span>
          </h1>

          {/* Description */}
          <p className="text-lg text-neutral-400 font-light leading-relaxed mb-10 max-w-xl">
            Premium goods designed with intention. Quality craft meets enduring design, curated for
            those who appreciate the exceptional.
          </p>

          {/* CTAs */}
          <div className="flex items-center gap-4">
            <a
              href="#products"
              className="group inline-flex items-center gap-3 px-6 py-3.5 bg-white text-black text-sm font-medium rounded-full hover:bg-neutral-100 transition-all duration-200"
            >
              Shop collection
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                className="group-hover:translate-x-0.5 transition-transform duration-200"
              >
                <line x1="5" y1="12" x2="19" y2="12" />
                <polyline points="12 5 19 12 12 19" />
              </svg>
            </a>

            {!user && (
              <button
                onClick={onSignInClick}
                className="px-6 py-3.5 text-sm font-medium text-neutral-300 hover:text-white border border-neutral-700 hover:border-neutral-500 rounded-full transition-all duration-200"
              >
                Sign in
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="absolute bottom-10 right-8 md:right-16 hidden md:flex items-center gap-12">
        {STATS.map(({ value, label }) => (
          <div key={label} className="text-right">
            <p className="text-2xl font-light text-white mb-1">{value}</p>
            <p className="text-xs font-medium text-neutral-500 uppercase tracking-wider">{label}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

export default Hero;
