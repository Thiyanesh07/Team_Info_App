'use client';
import { GoogleLogin } from '@react-oauth/google';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import axios from 'axios';
import { jwtDecode } from 'jwt-decode';

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSuccess = async (credentialResponse: any) => {
    try {
      setLoading(true);
      setError('');
      
      const token = credentialResponse.credential;
      const decoded: any = jwtDecode(token);
      
      // Call backend to verify and get admin status
      const res = await axios.post(`${process.env.NEXT_PUBLIC_API_URL}/auth/google`, {
        idToken: token
      });

      if (res.data.success) {
        const user = res.data.data.user;
        
        // Strict Admin Check
        if (user.role !== 'ADMIN') {
          setError('Access Denied: This dashboard is for Administrators only.');
          setLoading(false);
          return;
        }

        // Store token and redirect
        localStorage.setItem('admin_token', res.data.data.token);
        localStorage.setItem('admin_user', JSON.stringify(user));
        router.push('/');
      } else {
        setError(res.data.message || 'Authentication failed');
      }
    } catch (err: any) {
      console.error('Login error:', err);
      setError(err.response?.data?.message || 'Failed to connect to authentication server');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-slate-900 via-slate-950 to-black">
      <div className="max-w-md w-full space-y-8 bg-slate-900/50 backdrop-blur-xl p-10 rounded-3xl border border-slate-800 shadow-2xl">
        <div className="text-center">
          <div className="mx-auto h-16 w-16 bg-blue-500/10 rounded-2xl flex items-center justify-center border border-blue-500/20 mb-6">
            <svg className="w-8 h-8 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
          </div>
          <h2 className="text-3xl font-extrabold text-white tracking-tight">Admin Console</h2>
          <p className="mt-2 text-sm text-slate-400">
            Secure command center for team oversight
          </p>
        </div>

        <div className="mt-8 space-y-6">
          <div className="flex flex-col items-center gap-4">
            <GoogleLogin
              onSuccess={handleSuccess}
              onError={() => setError('Google Sign-In failed')}
              theme="filled_black"
              shape="pill"
            />
            {loading && <p className="text-blue-400 text-sm animate-pulse">Verifying credentials...</p>}
          </div>

          {error && (
            <div className="p-4 bg-red-500/10 border border-red-500/20 rounded-xl">
              <p className="text-sm text-red-400 text-center font-medium">{error}</p>
            </div>
          )}
        </div>

        <div className="pt-6 border-t border-slate-800/50">
          <p className="text-center text-xs text-slate-500 uppercase tracking-widest font-semibold">
            Authorized Personnel Only
          </p>
        </div>
      </div>
    </div>
  );
}
