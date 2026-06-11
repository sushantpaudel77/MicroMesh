function ProductCard({ product, onAddToCart, isAdding }) {
  const soldOut = product.stock === 0;
  const lowStock = product.stock > 0 && product.stock <= 5;

  return (
    <div className="product-card group bg-white border border-neutral-200 rounded-2xl overflow-hidden">
      {/* Image */}
      <div className="aspect-square bg-neutral-100 overflow-hidden relative">
        <img
          src={product.image_url || '/placeholder.jpg'}
          alt={product.name}
          className="w-full h-full object-cover group-hover:scale-[1.04] transition-transform duration-500"
          loading="lazy"
        />
        {soldOut && (
          <span className="absolute top-3 left-3 bg-neutral-950 text-white text-[10.5px] font-semibold px-2.5 py-1 rounded-full">
            Sold Out
          </span>
        )}
        {lowStock && (
          <span className="absolute top-3 left-3 bg-amber-500 text-white text-[10.5px] font-semibold px-2.5 py-1 rounded-full">
            Only {product.stock} left
          </span>
        )}
      </div>

      {/* Info */}
      <div className="p-4">
        <h3
          className="text-[14px] font-semibold text-neutral-900 truncate mb-1"
          style={{ fontFamily: "'DM Sans', sans-serif" }}
        >
          {product.name}
        </h3>
        <p
          className="text-[12.5px] text-neutral-500 line-clamp-2 leading-relaxed mb-4"
          style={{ fontFamily: "'DM Sans', sans-serif" }}
        >
          {product.description}
        </p>

        <div className="flex items-center justify-between mb-3.5">
          <span
            className="text-[18px] font-semibold text-neutral-950"
            style={{ fontFamily: "'Fraunces', serif" }}
          >
            ${parseFloat(product.price).toFixed(2)}
          </span>
          {product.stock > 5 && (
            <span className="flex items-center gap-1 text-[11.5px] font-medium text-emerald-600">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 inline-block" />
              In Stock
            </span>
          )}
        </div>

        <button
          onClick={() => onAddToCart(product)}
          disabled={isAdding || soldOut}
          className={`
            w-full py-2.5 text-[13px] font-semibold rounded-xl
            transition-all duration-200 flex items-center justify-center gap-2
            ${
              soldOut
                ? 'bg-neutral-100 text-neutral-400 cursor-not-allowed'
                : 'bg-neutral-950 text-white hover:bg-neutral-800 active:scale-[0.98] shadow-sm hover:shadow'
            }
            ${isAdding ? 'opacity-70' : ''}
          `}
          style={{ fontFamily: "'DM Sans', sans-serif" }}
        >
          {isAdding ? (
            <>
              <div className="w-3.5 h-3.5 border-2 border-white/40 border-t-white rounded-full animate-spin" />
              Adding...
            </>
          ) : soldOut ? (
            'Out of Stock'
          ) : (
            <>
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <circle cx="9" cy="21" r="1" />
                <circle cx="20" cy="21" r="1" />
                <path d="M1 1h4l2.68 13.39a2 2 0 001.99 1.61h9.72a2 2 0 001.98-1.69l1.6-9.3H6" />
              </svg>
              Add to Cart
            </>
          )}
        </button>
      </div>
    </div>
  );
}

export default ProductCard;
