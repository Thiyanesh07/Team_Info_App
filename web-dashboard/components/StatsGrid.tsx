'use client';
import { Users, CheckCircle2, Rocket, Trophy } from 'lucide-react';
import { cn } from '@/lib/utils';

interface Stat {
  name: string;
  value: string | number;
  icon: any;
  color: string;
  bg: string;
}

export default function StatsGrid({ stats }: { stats: any }) {
  const displayStats: Stat[] = [
    { name: 'Total Users', value: stats.totalUsers, icon: Users, color: 'text-blue-500', bg: 'bg-blue-500/10' },
    { name: 'Active Tasks', value: stats.tasks.total, icon: CheckCircle2, color: 'text-emerald-500', bg: 'bg-emerald-500/10' },
    { name: 'Projects', value: stats.projects.total, icon: Rocket, color: 'text-orange-500', bg: 'bg-orange-500/10' },
    { name: 'Hackathons', value: stats.counts.hackathons, icon: Trophy, color: 'text-purple-500', bg: 'bg-purple-500/10' },
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {displayStats.map((stat) => (
        <div 
          key={stat.name}
          className="bg-slate-900 border border-slate-800 p-6 rounded-2xl flex items-center gap-4 hover:border-slate-700 transition-all duration-300"
        >
          <div className={cn('p-3 rounded-xl border border-white/5 shadow-sm', stat.bg, stat.color)}>
            <stat.icon size={24} />
          </div>
          <div>
            <p className="text-slate-400 text-sm font-medium">{stat.name}</p>
            <h3 className="text-2xl font-bold text-white tracking-tight">{stat.value}</h3>
          </div>
        </div>
      ))}
    </div>
  );
}
