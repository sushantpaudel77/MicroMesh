import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../../api';
import { useCart } from '../../CartContext';

const CartIcon = ({ size = 48, className = '' }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.5"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <circle cx="9" cy="21" r="1" />
    <circle cx="20" cy="21" r="1" />
    <path d="M1 1h4l2.68 13.39a2 2 0 001.99 1.61h9.72a2 2 0 001.98-1.69l1.6-9.3H6" />
  </svg>
);

function Cart({ user, onSignInClick }) {
  const [cart, setCart] = useState(null);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState({ text: '', type: '' });
  const [checkingOut, setCheckingOut] = useState(false);
  const [removingId, setRemovingId] = useState(null);
  const { refreshCartCount } = useCart();

  useEffect(() => {
    if (user) loadCart();
    else setLoading(false);
  }, [user]);

  const loadCart = async () => {
    try {
      const data = await api.getCart();
      setCart(data);
    } catch {
      showMessage('Error loading cart', 'error');
    } finally {
      setLoading(false);
    }
  };

  const showMessage = (text, type = 'info') => {
    setMessage({ text, type });
    setTimeout(() => setMessage({ text: '', type: '' }), 4000);
  };

  const handleRemove = async (productId) => {
    setRemovingId(productId);
    try {
      await api.removeFromCart(productId);
      await loadCart();
      refreshCartCount();
    } catch {
      showMessage('Error removing item', 'error');
    } finally {
      setRemovingId(null);
    }
  };

  const handleCheckout = async () => {
    if (!cart?.items?.length) return;
    setCheckingOut(true);
    try {
      await api.createOrder();
      showMessage('Order placed successfully!', 'success');
      await loadCart();
      refreshCartCount();
    } catch {
      showMessage('Error placing order', 'error');
    } finally {
      setCheckingOut(false);
    }
  };

  const getTotal = () => {
    if (!cart?.items) return 0;
    return cart.items.reduce((s, i) => s + i.price * i.quantity, 0);
  };

  if (loading)
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="spinner" />
      </div>
    );

  if (!user)
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-5 px-6 text-center">
        <div className="w-16 h-16 rounded-2xl bg-neutral-100 flex items-center justify-center">
          <CartIcon size={28} className="text-neutral-400" />
        </div>
        <div>
          <p className="text-base font-semibold text-neutral-900 mb-1">Your cart awaits</p>
          <p className="text-[13.5px] text-neutral-500">
            <button
              onClick={onSignInClick}
              className="font-semibold underline underline-offset-2 hover:opacity-70 transition-opacity"
              style={{ color: '#ea2e0e' }}
            >
              Sign in
            </button>{' '}
            to view your cart and checkout
          </p>
        </div>
      </div>
    );

  const empty = !cart?.items?.length;

  return (
    <div className="max-w-2xl mx-auto w-full px-6 py-14 flex-1">
      {/* Header */}
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1
            className="text-[28px] font-bold text-neutral-950 tracking-tight"
            style={{ fontFamily: "'Fraunces', serif" }}
          >
            Shopping Cart
          </h1>
          {!empty && (
            <p
              className="text-[13px] text-neutral-500 mt-0.5"
              style={{ fontFamily: "'DM Sans', sans-serif" }}
            >
              {cart.items.length} item{cart.items.length !== 1 ? 's' : ''}
            </p>
          )}
        </div>
        {!empty && (
          <Link
            to="/"
            className="text-[13px] text-neutral-500 hover:text-neutral-900 transition-colors flex items-center gap-1.5"
            style={{ fontFamily: "'DM Sans', sans-serif" }}
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
              <line x1="19" y1="12" x2="5" y2="12" />
              <polyline points="12 19 5 12 12 5" />
            </svg>
            Continue shopping
          </Link>
        )}
      </div>

      {/* Toast */}
      {message.text && (
        <div
          className={`flex items-center gap-2.5 text-[13px] px-4 py-3 rounded-xl mb-5 font-medium
          ${
            message.type === 'success'
              ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
              : message.type === 'error'
                ? 'bg-red-50 text-red-700 border border-red-200'
                : 'bg-neutral-50 text-neutral-700 border border-neutral-200'
          }`}
          style={{ fontFamily: "'DM Sans', sans-serif" }}
        >
          {message.type === 'success' && (
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
          )}
          {message.text}
        </div>
      )}

      {/* Empty state */}
      {empty ? (
        <div className="text-center py-20">
          <div
            className="w-20 h-20 rounded-2xl bg-neutral-50 border border-neutral-100
            flex items-center justify-center mx-auto mb-5"
          >
            <CartIcon size={32} className="text-neutral-300" />
          </div>
          <p
            className="text-[16px] font-semibold text-neutral-900 mb-1.5"
            style={{ fontFamily: "'Fraunces', serif" }}
          >
            Your cart is empty
          </p>
          <p
            className="text-[13.5px] text-neutral-500 mb-6"
            style={{ fontFamily: "'DM Sans', sans-serif" }}
          >
            Add some products to get started
          </p>
          <Link
            to="/"
            className="inline-flex items-center gap-2 px-6 py-2.5 text-white
              text-[13px] font-semibold rounded-xl hover:opacity-90 transition-all"
            style={{ backgroundColor: '#ea2e0e', fontFamily: "'DM Sans', sans-serif" }}
          >
            Browse products
          </Link>
        </div>
      ) : (
        <>
          {/* Items */}
          <div className="space-y-2.5 mb-6">
            {cart.items.map((item) => {
              const isRemoving = removingId === item.product_id;
              return (
                <div
                  key={item.product_id}
                  className={`flex items-center gap-4 bg-white border border-neutral-200
                    rounded-xl px-5 py-4 transition-opacity duration-200
                    ${isRemoving ? 'opacity-40' : ''}`}
                >
                  <div className="w-10 h-10 rounded-lg bg-neutral-100 flex items-center justify-center flex-shrink-0">
                    <svg
                      width="16"
                      height="16"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="1.8"
                      className="text-neutral-400"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z" />
                    </svg>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p
                      className="text-[13.5px] font-semibold text-neutral-900 truncate"
                      style={{ fontFamily: "'DM Sans', sans-serif" }}
                    >
                      {item.product_id}
                    </p>
                    <p
                      className="text-[12px] text-neutral-500 mt-0.5"
                      style={{ fontFamily: "'DM Sans', sans-serif" }}
                    >
                      Qty {item.quantity} · ${parseFloat(item.price).toFixed(2)} each
                    </p>
                  </div>
                  <div className="flex items-center gap-4 flex-shrink-0">
                    <span
                      className="text-[15px] font-bold text-neutral-950"
                      style={{ fontFamily: "'Fraunces', serif" }}
                    >
                      ${(item.price * item.quantity).toFixed(2)}
                    </span>
                    <button
                      onClick={() => handleRemove(item.product_id)}
                      disabled={isRemoving}
                      aria-label="Remove item"
                      className="w-7 h-7 flex items-center justify-center rounded-lg border border-neutral-200
                        text-neutral-400 hover:text-red-500 hover:border-red-200 hover:bg-red-50
                        transition-all duration-150 disabled:opacity-40"
                    >
                      <svg
                        width="13"
                        height="13"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2.2"
                        strokeLinecap="round"
                      >
                        <line x1="18" y1="6" x2="6" y2="18" />
                        <line x1="6" y1="6" x2="18" y2="18" />
                      </svg>
                    </button>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Order Summary */}
          <div className="bg-white border border-neutral-200 rounded-2xl overflow-hidden">
            <div className="px-6 py-5 border-b border-neutral-100">
              <h2
                className="text-[13.5px] font-semibold text-neutral-950 uppercase tracking-wider"
                style={{ fontFamily: "'DM Sans', sans-serif" }}
              >
                Order Summary
              </h2>
            </div>
            <div className="px-6 py-5 space-y-3">
              {[
                {
                  label: 'Subtotal',
                  value: `$${getTotal().toFixed(2)}`,
                  cls: 'text-neutral-900 font-medium',
                },
                {
                  label: 'Shipping',
                  value: getTotal() >= 50 ? 'Free' : '$4.99',
                  cls: 'text-emerald-600 font-medium',
                },
                { label: 'Taxes', value: 'Calculated at checkout', cls: 'text-neutral-500' },
              ].map(({ label, value, cls }) => (
                <div key={label} className="flex justify-between text-[13.5px]">
                  <span
                    className="text-neutral-600"
                    style={{ fontFamily: "'DM Sans', sans-serif" }}
                  >
                    {label}
                  </span>
                  <span className={cls} style={{ fontFamily: "'DM Sans', sans-serif" }}>
                    {value}
                  </span>
                </div>
              ))}
            </div>
            <div className="px-6 py-5 border-t border-neutral-100 bg-neutral-50">
              <div className="flex justify-between items-center mb-4">
                <span
                  className="text-[14px] font-semibold text-neutral-950"
                  style={{ fontFamily: "'DM Sans', sans-serif" }}
                >
                  Total
                </span>
                <span
                  className="text-[22px] font-bold text-neutral-950"
                  style={{ fontFamily: "'Fraunces', serif" }}
                >
                  ${getTotal().toFixed(2)}
                </span>
              </div>
              <button
                onClick={handleCheckout}
                disabled={checkingOut}
                className={`w-full py-3.5 text-[13.5px] font-semibold rounded-xl
                  flex items-center justify-center gap-2.5 transition-all duration-200
                  ${
                    checkingOut
                      ? 'bg-neutral-200 text-neutral-400 cursor-not-allowed'
                      : 'text-white hover:opacity-90 active:scale-[0.99] shadow-sm hover:shadow'
                  }`}
                style={{
                  backgroundColor: checkingOut ? undefined : '#ea2e0e',
                  fontFamily: "'DM Sans', sans-serif",
                }}
              >
                {checkingOut ? (
                  <>
                    <div className="w-4 h-4 border-2 border-neutral-400/40 border-t-neutral-400 rounded-full animate-spin" />
                    Placing Order...
                  </>
                ) : (
                  <>
                    <svg
                      width="15"
                      height="15"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                    </svg>
                    Place Order
                  </>
                )}
              </button>
              <p
                className="text-center text-[11.5px] text-neutral-400 mt-3"
                style={{ fontFamily: "'DM Sans', sans-serif" }}
              >
                Secure checkout — your data is protected
              </p>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

export default Cart;
