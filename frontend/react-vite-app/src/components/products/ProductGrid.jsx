import ProductCard from './ProductCard';

function ProductGrid({ products, addingId, onAddToCart }) {
  return (
    <div id="products" className="max-w-7xl mx-auto w-full px-6 py-16">
      {/* Section header */}
      <div className="flex items-center justify-between mb-10">
        <div>
          <h2
            className="text-[26px] font-semibold text-neutral-950 tracking-tight"
            style={{ fontFamily: "'Fraunces', serif" }}
          >
            All Products
          </h2>
          <p
            className="text-[13px] text-neutral-500 mt-1"
            style={{ fontFamily: "'DM Sans', sans-serif" }}
          >
            {products.length} item{products.length !== 1 ? 's' : ''} available
          </p>
        </div>
        <div className="hidden md:block h-px bg-neutral-200 flex-1 ml-8" />
      </div>

      {/* Empty state */}
      {products.length === 0 ? (
        <div className="text-center py-24">
          <svg
            width="44"
            height="44"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            className="text-neutral-300 mx-auto mb-4"
          >
            <path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z" />
          </svg>
          <p
            className="text-neutral-400 text-[15px]"
            style={{ fontFamily: "'DM Sans', sans-serif" }}
          >
            No products available right now.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
          {products.map((product) => (
            <ProductCard
              key={product.product_id}
              product={product}
              onAddToCart={onAddToCart}
              isAdding={addingId === product.product_id}
            />
          ))}
        </div>
      )}
    </div>
  );
}

export default ProductGrid;
