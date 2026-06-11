import { TbBrandMeta } from 'react-icons/tb';
import { IoLogoInstagram } from 'react-icons/io';
import { RiTwitterXLine } from 'react-icons/ri';

function TopBar() {
  return (
    <div className="top-0 left-0 right-0 bg-rabbit-red text-white py-2 z-50">
      <div className="max-w-7xl mx-auto flex items-center justify-between px-6">
        {/* Left — social icons */}
        <div className="hidden md:flex items-center space-x-4">
          <a
            href="#"
            aria-label="Meta"
            className="hover:text-white/70 transition-colors duration-150"
          >
            <TbBrandMeta className="h-5 w-5" />
          </a>
          <a
            href="#"
            aria-label="Instagram"
            className="hover:text-white/70 transition-colors duration-150"
          >
            <IoLogoInstagram className="h-5 w-5" />
          </a>
          <a
            href="#"
            aria-label="X / Twitter"
            className="hover:text-white/70 transition-colors duration-150"
          >
            <RiTwitterXLine className="h-4 w-4" />
          </a>
        </div>

        {/* Centre — promo message */}
        <div className="text-sm text-center grow" style={{ fontFamily: "'DM Sans', sans-serif" }}>
          <span>We ship worldwide Fast and reliable shopping!</span>
        </div>

        {/* Right — phone */}
        <div className="text-sm hidden md:block" style={{ fontFamily: "'DM Sans', sans-serif" }}>
          <a href="tel:+12345558900" className="hover:text-white/70 transition-colors duration-150">
            +977 9777777777
          </a>
        </div>
      </div>
    </div>
  );
}

export default TopBar;
