import { useState, useEffect } from 'react';
import { api } from '../../api';
import { useCart } from '../../CartContext';
import Hero from './Hero';
import ProductGrid from './ProductGrid';

function Products({ user, onSignInClick }) {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [toast, setToast] = useState('');
  const [addingId, setAddingId] = useState(null);
  const { refreshCartCount } = useCart();

  useEffect(() => {
    loadProducts();
  }, []);

  const loadProducts = async () => {
    setError(false);
    setLoading(true);
    try {
      const data = await api.getProducts();
      setProducts(data);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  };

  const handleAddToCart = async (product) => {
    if (!user) {
      onSignInClick();
      return;
    }
    setAddingId(product.product_id);
    try {
      await api.addToCart(product.product_id, 1, product.price);
      setToast(`${product.name} added to cart`);
      refreshCartCount();
      setTimeout(() => setToast(''), 3000);
    } catch {
      setToast('Could not add item please try again');
      setTimeout(() => setToast(''), 3000);
    } finally {
      setAddingId(null);
    }
  };

  if (loading)
    return (
      <div className="flex-1 flex items-center justify-center min-h-[60vh]">
        <div className="spinner" />
      </div>
    );

  return (
    <div className="flex-1 flex flex-col">
      <Hero user={user} onSignInClick={onSignInClick} />

      {/* Toast */}
      {toast && (
        <div
          className="fixed bottom-8 inset-x-0 mx-auto w-fit z-50 toast-enter
         bg-neutral-950 text-white text-[13px] font-medium
          px-5 py-3 rounded-xl shadow-2xl flex items-center gap-2.5 whitespace-nowrap"
          style={{ fontFamily: "'DM Sans', sans-serif" }}
        >
          <svg
            width="14"
            height="14"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <polyline points="20 6 9 17 4 12" />
          </svg>
          {toast}
        </div>
      )}

      {error ? (
        /* ── Error state ── */
        <div className="flex-1 flex items-center justify-center px-6 py-24">
          <div className="max-w-sm w-full text-center">
            <div
              className="w-16 h-16 rounded-2xl bg-red-50 border border-red-100
              flex items-center justify-center mx-auto mb-5"
            >
              <svg
                width="26"
                height="26"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#ea2e0e"
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <circle cx="12" cy="12" r="10" />
                <line x1="12" y1="8" x2="12" y2="12" />
                <line x1="12" y1="16" x2="12.01" y2="16" />
              </svg>
            </div>
            <h3
              className="text-[20px] font-semibold text-neutral-900 mb-2"
              style={{ fontFamily: "'Fraunces', serif" }}
            >
              Couldn't load products
            </h3>
            <p
              className="text-[14px] text-neutral-500 leading-relaxed mb-6"
              style={{ fontFamily: "'DM Sans', sans-serif" }}
            >
              We hit a snag reaching our servers. Check your connection or try again in a moment.
            </p>
            <button
              onClick={loadProducts}
              className="inline-flex items-center gap-2 px-6 py-2.5 text-white
                text-[13.5px] font-semibold rounded-xl
                hover:opacity-90 active:scale-[0.97] transition-all duration-200"
              style={{ backgroundColor: '#ea2e0e', fontFamily: "'DM Sans', sans-serif" }}
            >
              <svg
                width="13"
                height="13"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polyline points="23 4 23 10 17 10" />
                <path d="M20.49 15a9 9 0 11-2.12-9.36L23 10" />
              </svg>
              Retry
            </button>
          </div>
        </div>
      ) : (
        <ProductGrid products={products} addingId={addingId} onAddToCart={handleAddToCart} />
      )}
    </div>
  );
}

export default Products;
