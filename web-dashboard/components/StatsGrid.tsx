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
    { name: 'Total Personnel', value: stats.totalUsers, icon: Users, color: 'text-[#EFD395]', bg: 'bg-[#131313]' },
    { name: 'Active Tasks', value: stats.tasks.total, icon: CheckCircle2, color: 'text-[#EFD395]', bg: 'bg-[#131313]' },
    { name: 'Project Directives', value: stats.projects.total, icon: Rocket, color: 'text-[#EFD395]', bg: 'bg-[#131313]' },
    { name: 'Operational Outcomes', value: stats.counts.hackathons, icon: Trophy, color: 'text-[#EFD395]', bg: 'bg-[#131313]' },
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
      {displayStats.map((stat) => (
        <div 
          key={stat.name}
          className="bg-[#262625] border border-[#4B4A48] p-8 rounded flex items-center gap-6 hover:border-[#EFD395]/40 transition-all duration-500 group shadow-2xl relative overflow-hidden"
        >
          <div className="absolute top-0 right-0 w-24 h-24 bg-gradient-to-bl from-[#EFD395]/5 to-transparent pointer-events-none" />
          <div className={cn('h-14 w-14 flex-shrink-0 rounded bg-[#131313] border border-[#4B4A48] flex items-center justify-center shadow-inner group-hover:border-[#EFD395] transition-colors', stat.color)}>
            <stat.icon size={26} />
          </div>
          <div className="z-10">
            <p className="text-[#A4A4A4] text-[10px] font-black uppercase tracking-[0.3em] italic mb-1 opacity-60 group-hover:opacity-100 transition-opacity">{stat.name}</p>
            <h3 className="text-3xl font-black text-white italic tracking-tighter leading-none">{stat.value}</h3>
          </div>
          <div className="absolute -bottom-2 -right-2 text-[#131313] font-black text-5xl uppercase italic tracking-tighter opacity-[0.03] select-none pointer-events-none group-hover:opacity-[0.05] transition-opacity">STAT</div>
        </div>
      ))}
    </div>
  );
}
