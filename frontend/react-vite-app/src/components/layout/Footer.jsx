import { Link } from 'react-router-dom';
import { PiRabbitFill } from 'react-icons/pi';
import { TbBrandMeta } from 'react-icons/tb';
import { IoLogoInstagram } from 'react-icons/io';
import { RiTwitterXLine } from 'react-icons/ri';

const FOOTER_LINKS = [
  {
    title: 'Shop',
    links: [
      { label: 'All Products', to: '/' },
      { label: 'My Cart', to: '/cart' },
      { label: 'My Orders', to: '/orders' },
    ],
  },
  {
    title: 'Company',
    links: [
      { label: 'About Us', href: '#' },
      { label: 'Careers', href: '#' },
      { label: 'Blog', href: '#' },
    ],
  },
  {
    title: 'Support',
    links: [
      { label: 'Help Center', href: '#' },
      { label: 'Contact Us', href: '#' },
      { label: 'Returns', href: '#' },
    ],
  },
  {
    title: 'Legal',
    links: [
      { label: 'Privacy Policy', href: '#' },
      { label: 'Terms of Service', href: '#' },
      { label: 'Cookie Policy', href: '#' },
    ],
  },
];

const TRUST_BADGES = [
  {
    icon: (
      <svg
        width="20"
        height="20"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <rect x="1" y="3" width="15" height="13" rx="1" />
        <path d="M16 8h5a1 1 0 011 1v9a1 1 0 01-1 1h-5" />
        <path d="M12 17v2M4 17v2" />
      </svg>
    ),
    label: 'Fast Shipping',
    sub: 'Worldwide delivery',
  },
  {
    icon: (
      <svg
        width="20"
        height="20"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
      </svg>
    ),
    label: 'Secure Payments',
    sub: 'SSL encrypted checkout',
  },
  {
    icon: (
      <svg
        width="20"
        height="20"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <polyline points="23 4 23 10 17 10" />
        <path d="M20.49 15a9 9 0 11-2.12-9.36L23 10" />
      </svg>
    ),
    label: '30-Day Returns',
    sub: 'Hassle-free refunds',
  },
  {
    icon: (
      <svg
        width="20"
        height="20"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z" />
      </svg>
    ),
    label: '24/7 Support',
    sub: "We're here to help",
  },
];

function Footer() {
  return (
    <footer className="bg-white border-t border-neutral-200 mt-auto">
      {/* Trust badges */}
      <div className="border-b border-neutral-100">
        <div className="max-w-7xl mx-auto px-6 py-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {TRUST_BADGES.map(({ icon, label, sub }) => (
              <div key={label} className="flex items-center gap-3">
                <div
                  className="w-10 h-10 rounded-xl bg-neutral-50 border border-neutral-100
                  flex items-center justify-center flex-shrink-0"
                  style={{ color: '#ea2e0e' }}
                >
                  {icon}
                </div>
                <div>
                  <p
                    className="text-[13px] font-semibold text-neutral-800"
                    style={{ fontFamily: "'DM Sans', sans-serif" }}
                  >
                    {label}
                  </p>
                  <p
                    className="text-[11.5px] text-neutral-500"
                    style={{ fontFamily: "'DM Sans', sans-serif" }}
                  >
                    {sub}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Main grid */}
      <div className="max-w-7xl mx-auto px-6 py-14">
        <div className="grid grid-cols-1 md:grid-cols-5 gap-10">
          {/* Brand column */}
          <div className="md:col-span-1 space-y-4">
            <Link to="/" className="flex items-center gap-1.5 group w-fit">
              <PiRabbitFill className="w-7 h-7 text-rabbit-red transition-opacity duration-150 group-hover:opacity-80" />
              <span
                className="text-[16px] font-bold text-neutral-950 tracking-tight"
                style={{ fontFamily: "'Fraunces', serif" }}
              >
                Rabbit
              </span>
            </Link>
            <p
              className="text-[13px] text-neutral-500 leading-relaxed max-w-[200px]"
              style={{ fontFamily: "'DM Sans', sans-serif" }}
            >
              Premium products curated for modern living.
            </p>

            {/* Social — using react-icons */}
            <div className="flex gap-2 pt-1">
              <a
                href="#"
                aria-label="Meta"
                className="w-8 h-8 rounded-lg border border-neutral-200 flex items-center justify-center
                  text-neutral-400 hover:border-neutral-300 transition-all duration-150"
                style={{ ':hover': { color: '#ea2e0e' } }}
                onMouseEnter={(e) => (e.currentTarget.style.color = '#ea2e0e')}
                onMouseLeave={(e) => (e.currentTarget.style.color = '')}
              >
                <TbBrandMeta size={15} />
              </a>
              <a
                href="#"
                aria-label="Instagram"
                className="w-8 h-8 rounded-lg border border-neutral-200 flex items-center justify-center
                  text-neutral-400 hover:border-neutral-300 transition-all duration-150"
                onMouseEnter={(e) => (e.currentTarget.style.color = '#ea2e0e')}
                onMouseLeave={(e) => (e.currentTarget.style.color = '')}
              >
                <IoLogoInstagram size={15} />
              </a>
              <a
                href="#"
                aria-label="X / Twitter"
                className="w-8 h-8 rounded-lg border border-neutral-200 flex items-center justify-center
                  text-neutral-400 hover:border-neutral-300 transition-all duration-150"
                onMouseEnter={(e) => (e.currentTarget.style.color = '#ea2e0e')}
                onMouseLeave={(e) => (e.currentTarget.style.color = '')}
              >
                <RiTwitterXLine size={14} />
              </a>
            </div>
          </div>

          {/* Link columns */}
          {FOOTER_LINKS.map(({ title, links }) => (
            <div key={title} className="space-y-3">
              <p
                className="text-[11.5px] font-semibold text-neutral-400 uppercase tracking-widest"
                style={{ fontFamily: "'DM Sans', sans-serif" }}
              >
                {title}
              </p>
              <ul className="space-y-2">
                {links.map(({ label, to, href }) => (
                  <li key={label}>
                    {to ? (
                      <Link
                        to={to}
                        className="text-[13px] text-neutral-500 hover:text-neutral-900 transition-colors duration-150"
                        style={{ fontFamily: "'DM Sans', sans-serif" }}
                      >
                        {label}
                      </Link>
                    ) : (
                      <a
                        href={href}
                        className="text-[13px] text-neutral-500 hover:text-neutral-900 transition-colors duration-150"
                        style={{ fontFamily: "'DM Sans', sans-serif" }}
                      >
                        {label}
                      </a>
                    )}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>

      {/* Bottom bar */}
      <div className="border-t border-neutral-100">
        <div className="max-w-7xl mx-auto px-6 py-5 flex flex-col sm:flex-row items-center justify-between gap-3">
          <p
            className="text-[12px] text-neutral-400"
            style={{ fontFamily: "'DM Sans', sans-serif" }}
          >
            © {new Date().getFullYear()} Rabbit, Inc. All rights reserved.
          </p>
          <div
            className="flex items-center gap-1.5 text-[12px] text-neutral-400"
            style={{ fontFamily: "'DM Sans', sans-serif" }}
          >
            <span>Built with</span>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="#ea2e0e" stroke="none">
              <path d="M12 21.593c-5.63-5.539-11-10.297-11-14.402 0-3.791 3.068-5.191 5.281-5.191 1.312 0 4.151.501 5.719 4.457 1.59-3.968 4.464-4.447 5.726-4.447 2.54 0 5.274 1.621 5.274 5.181 0 4.069-5.136 8.625-11 14.402z" />
            </svg>
            <span>Rabbit</span>
          </div>
        </div>
      </div>
    </footer>
  );
}

export default Footer;
