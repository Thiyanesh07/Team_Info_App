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
    <div className="min-h-screen flex items-center justify-center p-4 bg-[#131313] relative overflow-hidden">
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_0%,rgba(239,211,149,0.03),transparent_60%)] pointer-events-none" />
      <div className="absolute bottom-10 left-10 text-[120px] font-black uppercase italic text-[#FFFFFF] opacity-[0.02] select-none tracking-tighter leading-none">COMMAND</div>
      
      <div className="max-w-md w-full space-y-10 bg-[#262625] p-12 md:p-16 rounded border border-[#4B4A48] shadow-2xl relative z-10 group">
        <div className="text-center">
          <div className="mx-auto h-20 w-20 bg-[#131313] rounded border border-[#4B4A48] flex items-center justify-center mb-8 shadow-inner group-hover:border-[#EFD395] transition-colors">
            <svg className="w-10 h-10 text-[#EFD395]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
          </div>
          <h2 className="text-4xl md:text-5xl font-black text-white uppercase italic tracking-tighter">Admin Console</h2>
          <p className="mt-4 text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.4em] italic opacity-60">
            Secure command center for team oversight
          </p>
        </div>

        <div className="space-y-8">
          <div className="flex flex-col items-center gap-6">
            <div className="w-full flex justify-center scale-110">
              <GoogleLogin
                onSuccess={handleSuccess}
                onError={() => setError('Google Sign-In failed')}
                theme="filled_black"
                shape="rectangular"
              />
            </div>
            {loading && <p className="text-[#EFD395] text-[10px] font-black uppercase tracking-[0.3em] animate-pulse italic">Verifying credentials...</p>}
          </div>

          {error && (
            <div className="p-5 bg-red-600/10 border border-red-500/20 rounded">
              <p className="text-[10px] text-red-500 text-center font-black uppercase tracking-[0.2em] italic">{error}</p>
            </div>
          )}
        </div>

        <div className="pt-8 border-t border-[#4B4A48] text-center">
          <div className="inline-flex items-center gap-4">
            <div className="h-[1px] w-8 bg-gradient-to-r from-transparent to-[#4B4A48]" />
            <p className="text-[9px] font-black text-[#777674] uppercase tracking-[0.5em] italic">
              Personnel Only
            </p>
            <div className="h-[1px] w-8 bg-gradient-to-l from-transparent to-[#4B4A48]" />
          </div>
        </div>
      </div>
    </div>
  );
}
