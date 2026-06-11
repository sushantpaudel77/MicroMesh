import { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { PiRabbitFill } from 'react-icons/pi';
import { useCart } from '../../CartContext';
import TopBar from './TopBar';

function Navbar({ signOut, user, onSignInClick }) {
  const displayName = user?.signInDetails?.loginId || user?.username || '';
  const { cartCount } = useCart();
  const location = useLocation();
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 6);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    setMobileMenuOpen(false);
  }, [location.pathname]);

  const navLinks = [
    { to: '/', label: 'Shop' },
    { to: '/cart', label: 'Cart', badge: cartCount },
    { to: '/orders', label: 'Orders' },
  ];

  return (
    <header className="sticky top-0 z-50">
      <TopBar />

      <nav
        className={`bg-white/96 backdrop-blur-xl border-b transition-all duration-200 ${
          scrolled
            ? 'border-neutral-200 shadow-[0_1px_12px_rgba(0,0,0,0.06)]'
            : 'border-neutral-100'
        }`}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 h-[64px] flex items-center justify-between gap-4">
          {/* Brand */}
          <Link to="/" className="flex items-center gap-1.5 flex-shrink-0 group w-[200px]">
            <PiRabbitFill className="w-7 h-7 sm:w-8 sm:h-8 text-rabbit-red transition-opacity duration-150 group-hover:opacity-80" />
            <span className="text-[16px] sm:text-[18px] font-bold text-neutral-950 tracking-tight flex items-center">
              Rabbit
              <span className="ml-1 size-1 mt-2 bg-rabbit-red rounded-full inline-block" />
            </span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-0.5 flex-1 justify-center">
            {navLinks.map(({ to, label, badge }) => {
              const active = location.pathname === to;
              return (
                <Link
                  key={to}
                  to={to}
                  className={`
                    relative flex items-center gap-1.5 px-4 py-2 rounded-lg
                    text-[13.5px] font-medium transition-all duration-150 select-none
                    ${
                      active
                        ? 'text-neutral-950 bg-neutral-100'
                        : 'text-neutral-500 hover:text-neutral-900 hover:bg-neutral-50'
                    }
                  `}
                >
                  {label}
                  {badge > 0 && (
                    <span className="text-white text-[9px] font-bold rounded-full min-w-[17px] h-[17px] flex items-center justify-center px-1 leading-none bg-rabbit-red">
                      {badge > 99 ? '99+' : badge}
                    </span>
                  )}
                  {active && (
                    <span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-4 h-[2px] rounded-full bg-rabbit-red" />
                  )}
                </Link>
              );
            })}
          </div>

          {/* Desktop Auth */}

          <div className="hidden md:flex items-center gap-3 flex-shrink-0 justify-end w-[180px]">
            {user ? (
              <>
                <div className="flex items-center gap-2.5 pr-1">
                  <div className="w-7 h-7 rounded-full bg-rabbit-red flex items-center justify-center flex-shrink-0">
                    <span className="text-[11px] font-bold text-white uppercase">
                      {displayName.charAt(0)}
                    </span>
                  </div>
                  <span className="text-[13px] text-neutral-500 max-w-[130px] truncate">
                    {displayName}
                  </span>
                </div>

                <button
                  onClick={signOut}
                  className="flex items-center gap-1.5 px-3.5 py-1.5 text-[13px] font-medium
                   text-neutral-500 hover:text-neutral-900
                  transition-colors duration-150"
                >
                  <svg
                    width="13"
                    height="13"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4" />
                    <polyline points="16 17 21 12 16 7" />
                    <line x1="21" y1="12" x2="9" y2="12" />
                  </svg>
                  Sign out
                </button>
              </>
            ) : (
              <button
                onClick={onSignInClick}
                className="flex items-center gap-1.5 px-5 py-2 text-[13.5px] font-semibold
                  text-white bg-rabbit-red rounded-lg shadow-sm
                  hover:opacity-90 active:scale-[0.97] transition-all duration-150"
              >
                Sign in
              </button>
            )}
          </div>

          {/* Mobile Right Section */}
          <div className="flex md:hidden items-center gap-2">
            {user ? (
              <div className="w-7 h-7 rounded-full bg-rabbit-red flex items-center justify-center">
                <span className="text-[11px] font-bold text-white uppercase">
                  {displayName.charAt(0)}
                </span>
              </div>
            ) : (
              <button
                onClick={onSignInClick}
                className="text-[12px] font-semibold text-white bg-rabbit-red px-3 py-1.5 rounded-md"
              >
                Sign in
              </button>
            )}

            {/* Mobile Menu Button */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-2 -mr-2 text-neutral-600 hover:text-neutral-900 transition-colors"
              aria-label="Toggle menu"
            >
              {mobileMenuOpen ? (
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <line x1="18" y1="6" x2="6" y2="18" />
                  <line x1="6" y1="6" x2="18" y2="18" />
                </svg>
              ) : (
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <line x1="3" y1="12" x2="21" y2="12" />
                  <line x1="3" y1="6" x2="21" y2="6" />
                  <line x1="3" y1="18" x2="21" y2="18" />
                </svg>
              )}
            </button>
          </div>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className="md:hidden border-t border-neutral-100 bg-white">
            <div className="px-4 py-3 space-y-1">
              {navLinks.map(({ to, label, badge }) => {
                const active = location.pathname === to;
                return (
                  <Link
                    key={to}
                    to={to}
                    className={`
                      flex items-center justify-between px-4 py-3 rounded-lg
                      text-sm font-medium transition-all duration-150
                      ${
                        active
                          ? 'text-neutral-950 bg-neutral-100'
                          : 'text-neutral-500 hover:text-neutral-900 hover:bg-neutral-50'
                      }
                    `}
                  >
                    <span>{label}</span>
                    {badge > 0 && (
                      <span className="text-white text-[9px] font-bold rounded-full min-w-[17px] h-[17px] flex items-center justify-center px-1 leading-none bg-rabbit-red">
                        {badge > 99 ? '99+' : badge}
                      </span>
                    )}
                  </Link>
                );
              })}

              {/* Mobile User Info & Sign Out */}
              {user && (
                <div className="pt-3 mt-3 border-t border-neutral-100">
                  <div className="flex items-center gap-3 px-4 py-2">
                    <div className="w-8 h-8 rounded-full bg-rabbit-red flex items-center justify-center flex-shrink-0">
                      <span className="text-xs font-bold text-white uppercase">
                        {displayName.charAt(0)}
                      </span>
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-neutral-900 truncate">{displayName}</p>
                    </div>
                  </div>
                  <button
                    onClick={signOut}
                    className="w-full mt-2 flex items-center gap-2 px-4 py-2.5 text-sm font-medium
                      text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50 rounded-lg
                      transition-all duration-150"
                  >
                    <svg
                      width="14"
                      height="14"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4" />
                      <polyline points="16 17 21 12 16 7" />
                      <line x1="21" y1="12" x2="9" y2="12" />
                    </svg>
                    Sign out
                  </button>
                </div>
              )}
            </div>
          </div>
        )}
      </nav>
    </header>
  );
}

export default Navbar;
