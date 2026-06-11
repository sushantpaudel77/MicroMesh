import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../../api';

const STATUS_CONFIG = {
  'Order Placed': { dot: 'bg-blue-400', pill: 'bg-blue-50 text-blue-700 border-blue-200' },
  Processing: { dot: 'bg-purple-400', pill: 'bg-purple-50 text-purple-700 border-purple-200' },
  Shipped: { dot: 'bg-amber-400', pill: 'bg-amber-50 text-amber-700 border-amber-200' },
  Delivered: { dot: 'bg-emerald-400', pill: 'bg-emerald-50 text-emerald-700 border-emerald-200' },
  Cancelled: { dot: 'bg-red-400', pill: 'bg-red-50 text-red-700 border-red-200' },
};

const BoxIcon = ({ size = 48, className = '' }) => (
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
    <path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z" />
    <polyline points="3.27 6.96 12 12.01 20.73 6.96" />
    <line x1="12" y1="22.08" x2="12" y2="12" />
  </svg>
);

function Orders({ user, onSignInClick }) {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (user) loadOrders();
    else setLoading(false);
  }, [user]);

  const loadOrders = async () => {
    try {
      const data = await api.getOrders();
      setOrders(data);
    } catch (err) {
      console.error('Error loading orders:', err);
    } finally {
      setLoading(false);
    }
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
          <BoxIcon size={28} className="text-neutral-400" />
        </div>
        <div>
          <p className="text-base font-semibold text-neutral-900 mb-1">Track your orders</p>
          <p
            className="text-[13.5px] text-neutral-500"
            style={{ fontFamily: "'DM Sans', sans-serif" }}
          >
            <button
              onClick={onSignInClick}
              className="font-semibold underline underline-offset-2 hover:opacity-70 transition-opacity"
              style={{ color: '#ea2e0e' }}
            >
              Sign in
            </button>{' '}
            to view your order history
          </p>
        </div>
      </div>
    );

  return (
    <div className="max-w-2xl mx-auto w-full px-6 py-14 flex-1">
      {/* Header */}
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1
            className="text-[28px] font-bold text-neutral-950 tracking-tight"
            style={{ fontFamily: "'Fraunces', serif" }}
          >
            Your Orders
          </h1>
          <p
            className="text-[13px] text-neutral-500 mt-0.5"
            style={{ fontFamily: "'DM Sans', sans-serif" }}
          >
            {orders.length} order{orders.length !== 1 ? 's' : ''}
          </p>
        </div>
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
          Back to shop
        </Link>
      </div>

      {orders.length === 0 ? (
        <div className="text-center py-20">
          <div
            className="w-20 h-20 rounded-2xl bg-neutral-50 border border-neutral-100
            flex items-center justify-center mx-auto mb-5"
          >
            <BoxIcon size={30} className="text-neutral-300" />
          </div>
          <p
            className="text-[16px] font-semibold text-neutral-900 mb-1.5"
            style={{ fontFamily: "'Fraunces', serif" }}
          >
            No orders yet
          </p>
          <p
            className="text-[13.5px] text-neutral-500 mb-6"
            style={{ fontFamily: "'DM Sans', sans-serif" }}
          >
            Your orders will appear here after checkout
          </p>
          <Link
            to="/"
            className="inline-flex items-center gap-2 px-6 py-2.5 text-white
              text-[13px] font-semibold rounded-xl hover:opacity-90 transition-all"
            style={{ backgroundColor: '#ea2e0e', fontFamily: "'DM Sans', sans-serif" }}
          >
            Start shopping
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          {orders.map((order) => {
            const config = STATUS_CONFIG[order.status] || {
              dot: 'bg-neutral-400',
              pill: 'bg-neutral-100 text-neutral-600 border-neutral-200',
            };
            return (
              <div
                key={order.id}
                className="bg-white border border-neutral-200 rounded-2xl overflow-hidden
                  hover:shadow-sm transition-shadow duration-200"
              >
                {/* Order header */}
                <div className="flex items-center justify-between px-5 py-4 border-b border-neutral-100">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-xl bg-neutral-100 flex items-center justify-center flex-shrink-0">
                      <BoxIcon size={16} className="text-neutral-500" />
                    </div>
                    <div>
                      <p className="text-[11px] text-neutral-400 uppercase tracking-wider leading-none mb-0.5">
                        Order
                      </p>
                      <p className="text-[14px] font-bold text-neutral-950 font-mono">
                        #{order.id}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <span
                      className="hidden sm:block text-[12px] text-neutral-400"
                      style={{ fontFamily: "'DM Sans', sans-serif" }}
                    >
                      {new Date(order.created_at).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                      })}
                    </span>
                    <span
                      className={`inline-flex items-center gap-1.5 text-[11.5px] font-semibold
                      px-2.5 py-1 rounded-full border ${config.pill}`}
                      style={{ fontFamily: "'DM Sans', sans-serif" }}
                    >
                      <span className={`w-1.5 h-1.5 rounded-full ${config.dot}`} />
                      {order.status}
                    </span>
                  </div>
                </div>

                {/* Items */}
                <div className="px-5 py-3 divide-y divide-neutral-50">
                  {order.items.map((item, idx) => (
                    <div key={idx} className="flex justify-between items-center py-2.5">
                      <span
                        className="text-[13px] text-neutral-700 flex-1 truncate pr-4"
                        style={{ fontFamily: "'DM Sans', sans-serif" }}
                      >
                        {item.product_id}
                      </span>
                      <div className="flex items-center gap-5 text-[12.5px] text-neutral-500 flex-shrink-0">
                        <span
                          className="bg-neutral-100 px-2 py-0.5 rounded-md font-medium"
                          style={{ fontFamily: "'DM Sans', sans-serif" }}
                        >
                          ×{item.quantity}
                        </span>
                        <span
                          className="font-medium text-neutral-700"
                          style={{ fontFamily: "'Fraunces', serif" }}
                        >
                          ${parseFloat(item.price).toFixed(2)}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>

                {/* Total */}
                <div
                  className="flex justify-between items-center px-5 py-4
                  border-t border-neutral-100 bg-neutral-50/70"
                >
                  <span
                    className="text-[12px] text-neutral-500 uppercase tracking-wider font-medium"
                    style={{ fontFamily: "'DM Sans', sans-serif" }}
                  >
                    Order Total
                  </span>
                  <span
                    className="text-[16px] font-bold text-neutral-950"
                    style={{ fontFamily: "'Fraunces', serif" }}
                  >
                    ${parseFloat(order.total_amount).toFixed(2)}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default Orders;
