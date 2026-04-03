'use client';
import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { LayoutDashboard, Users, UserSearch, LogOut, ShieldCheck, Rocket, CheckSquare, Trophy, FileText, Activity, Menu, X } from 'lucide-react';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';

const navItems = [
  { name: 'Dashboard', icon: LayoutDashboard, href: '/' },
  { name: 'Members', icon: Users, href: '/members' },
  { name: 'Projects', icon: Rocket, href: '/projects' },
  { name: 'Hackathons', icon: Trophy, href: '/hackathons' },
  { name: 'Tasks', icon: CheckSquare, href: '/tasks' },
  { name: 'Reports', icon: FileText, href: '/reports' },
  { name: 'Rewards', icon: Trophy, href: '/rewards' },
  { name: 'Admin Support', icon: ShieldCheck, href: '/chat' },
  { name: 'Inspection', icon: UserSearch, href: '/inspection' },
  { name: 'Security Audit', icon: Activity, href: '/audit' },
];

export default function Sidebar() {
  const pathname = usePathname();
  const [isOpen, setIsOpen] = useState(false);

  const handleLogout = () => {
    if (window.confirm('Terminate administrative session?')) {
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_user');
      window.location.href = '/login';
    }
  };

  const navContent = (
    <div className="flex flex-col h-full">
      <div className="p-8">
        <h1 className="text-lg font-black text-[#E0E0E0] flex items-center gap-2 uppercase tracking-tighter">
          <ShieldCheck className="text-[#888888]" size={20} />
          TMA A#100074
        </h1>
      </div>

      <nav className="flex-1 px-4 space-y-1 overflow-y-auto custom-scrollbar">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => setIsOpen(false)}
              className={cn(
                'flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 group border',
                isActive 
                  ? 'bg-[#444444]/20 text-[#E0E0E0] border-[#888888]/30 shadow-sm' 
                  : 'text-[#B0B0B0] border-transparent hover:bg-[#444444]/10 hover:text-[#E0E0E0]'
              )}
            >
              <item.icon size={18} className={cn(isActive ? 'text-[#E0E0E0]' : 'text-[#888888] group-hover:text-white')} />
              <span className="text-[10px] font-black uppercase tracking-widest">{item.name}</span>
            </Link>
          );
        })}
      </nav>

      <div className="p-4 border-t border-[#444444]">
        <button 
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-[#B0B0B0] hover:bg-red-500/10 hover:text-red-400 transition-all duration-200 border border-transparent hover:border-red-500/20"
        >
          <LogOut size={18} />
          <span className="text-xs font-bold uppercase tracking-widest">Logout</span>
        </button>
      </div>
    </div>
  );

  return (
    <>
      {/* Mobile Header/Toggle */}
      <div className="lg:hidden fixed top-0 left-0 right-0 z-[60] p-4 bg-[#121212]/80 backdrop-blur-md border-b border-[#444444] flex items-center justify-between">
         <h1 className="text-xs font-black text-[#E0E0E0] uppercase tracking-widest">TMA A#100074</h1>
         <button 
           onClick={() => setIsOpen(!isOpen)}
           className="p-2 border border-[#444444] rounded text-[#E0E0E0]"
         >
           {isOpen ? <X size={20} /> : <Menu size={20} />}
         </button>
      </div>

      {/* Desktop Sidebar */}
      <aside className="hidden lg:flex w-64 bg-[#121212] border-r border-[#444444] flex-col h-screen sticky top-0">
        {navContent}
      </aside>

      {/* Mobile Drawer Overlay */}
      <AnimatePresence>
        {isOpen && (
          <>
            <motion.div 
               initial={{ opacity: 0 }}
               animate={{ opacity: 1 }}
               exit={{ opacity: 0 }}
               onClick={() => setIsOpen(false)}
               className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm lg:hidden"
            />
            <motion.aside 
               initial={{ x: '-100%' }}
               animate={{ x: 0 }}
               exit={{ x: '-100%' }}
               transition={{ type: 'spring', damping: 25, stiffness: 200 }}
               className="fixed top-0 left-0 bottom-0 z-[70] w-72 bg-[#121212] border-r border-[#444444] flex flex-col lg:hidden"
            >
               {navContent}
            </motion.aside>
          </>
        )}
      </AnimatePresence>
    </>
  );
}
