import { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Authenticator, useAuthenticator } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';

import Navbar from './components/layout/Navbar';
import Footer from './components/layout/Footer';
import Products from './components/products/Products';
import Cart from './components/cart/Cart';
import Orders from './components/orders/Orders';

import { api } from './api';
import { CartProvider } from './CartContext';

function AppContent({ showLogin, setShowLogin }) {
  const { user, signOut } = useAuthenticator((context) => [context.user]);

  useEffect(() => {
    if (user) {
      setShowLogin(false);
      const email = user.signInDetails?.loginId || user.username;
      const name = user.username;
      api.getProfile().catch(() => {
        api
          .createProfile(email, name)
          .catch((err) => console.error('Failed to create profile:', err));
      });
    }
  }, [user]);

  return (
    <CartProvider user={user}>
      <Router>
        <div className="App min-h-screen flex flex-col bg-[#f9f9f9]">
          <Navbar signOut={signOut} user={user} onSignInClick={() => setShowLogin(true)} />

          {showLogin && !user && (
            <div
              className="login-overlay"
              onClick={(e) => {
                if (e.target === e.currentTarget) setShowLogin(false);
              }}
            >
              <div className="login-modal">
                <Authenticator signUpAttributes={['email', 'name']} />
              </div>
            </div>
          )}

          <main className="flex-1 flex flex-col">
            <Routes>
              <Route
                path="/"
                element={<Products user={user} onSignInClick={() => setShowLogin(true)} />}
              />
              <Route
                path="/cart"
                element={<Cart user={user} onSignInClick={() => setShowLogin(true)} />}
              />
              <Route
                path="/orders"
                element={<Orders user={user} onSignInClick={() => setShowLogin(true)} />}
              />
            </Routes>
          </main>

          <Footer />
        </div>
      </Router>
    </CartProvider>
  );
}

function App() {
  const [showLogin, setShowLogin] = useState(false);
  return (
    <Authenticator.Provider>
      <AppContent showLogin={showLogin} setShowLogin={setShowLogin} />
    </Authenticator.Provider>
  );
}

export default App;
