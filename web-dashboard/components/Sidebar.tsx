'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { LayoutDashboard, Users, UserSearch, LogOut, ShieldCheck, Rocket, CheckSquare, Trophy } from 'lucide-react';
import { cn } from '@/lib/utils';

const navItems = [
  { name: 'Dashboard', icon: LayoutDashboard, href: '/' },
  { name: 'Members', icon: Users, href: '/members' },
  { name: 'Projects', icon: Rocket, href: '/projects' },
  { name: 'Hackathons', icon: Trophy, href: '/hackathons' },
  { name: 'Tasks', icon: CheckSquare, href: '/tasks' },
  { name: 'Rewards', icon: Trophy, href: '/rewards' },
  { name: 'Inspection', icon: UserSearch, href: '/inspection' },
  { name: 'Security Audit', icon: ShieldCheck, href: '/audit' },
];

export default function Sidebar() {
  const pathname = usePathname();

  const handleLogout = () => {
    if (window.confirm('Are you sure you want to terminate your administrative session?')) {
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_user');
      window.location.href = '/login';
    }
  };

  return (
    <aside className="w-64 bg-slate-900 border-r border-slate-800 flex flex-col h-screen sticky top-0">
      <div className="p-6">
        <h1 className="text-xl font-bold bg-gradient-to-r from-blue-400 to-indigo-500 bg-clip-text text-transparent flex items-center gap-2">
          <ShieldCheck className="text-blue-500" />
          Admin Ops
        </h1>
      </div>

      <nav className="flex-1 px-4 space-y-1">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                'flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 group',
                isActive 
                  ? 'bg-blue-600/10 text-blue-400 border border-blue-500/20' 
                  : 'text-slate-400 hover:bg-slate-800 hover:text-white'
              )}
            >
              <item.icon size={20} className={cn(isActive ? 'text-blue-500' : 'text-slate-500 group-hover:text-blue-400')} />
              <span className="font-medium">{item.name}</span>
            </Link>
          );
        })}
      </nav>

      <div className="p-4 border-t border-slate-800">
        <button 
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-slate-400 hover:bg-red-500/10 hover:text-red-400 transition-all duration-200"
        >
          <LogOut size={20} />
          <span className="font-medium">Logout</span>
        </button>
      </div>
    </aside>
  );
}
