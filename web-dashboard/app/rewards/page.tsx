'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { toast } from 'sonner';
import { 
  Trophy, 
  Search, 
  CheckCircle2, 
  AlertCircle, 
  User, 
  ArrowUpRight,
  Calculator,
  RefreshCcw,
  Users
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { cn } from '@/lib/utils';

export default function RewardsStatus() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [filter, setFilter] = useState<'ALL' | 'ELIGIBLE' | 'BELOW'>('ALL');

  useEffect(() => {
    const controller = new AbortController();
    fetchStatus(controller.signal);
    return () => controller.abort();
  }, []);

  const fetchStatus = async (signal?: AbortSignal) => {
    try {
      setLoading(true);
      const res = await api.get('/analytics/reward-status', { signal });
      if (res.data.success) {
        setData(res.data.data);
      }
    } catch (err: any) {
      if (err.name === 'CanceledError') return;
      console.error('Fetch reward status error:', err);
      toast.error('Data Sync Failure', {
        description: 'Unable to retrieve eligibility status from the command center.',
      });
    } finally {
      setLoading(false);
    }
  };

  if (loading) return (
    <div className="flex h-screen bg-slate-950 items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500 shadow-lg shadow-blue-500/20"></div>
        <p className="text-slate-500 text-xs font-black uppercase tracking-[0.3em] animate-pulse">Calculating Eligibility Matrix</p>
      </div>
    </div>
  );

  const { yearlyTargets, teamStatus, summary } = data || { yearlyTargets: {}, teamStatus: [], summary: {} };

  const filteredMembers = teamStatus.filter((m: any) => {
    const matchesSearch = m.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
                         m.regNo.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = filter === 'ALL' || 
                         (filter === 'ELIGIBLE' && m.isEligible) || 
                         (filter === 'BELOW' && !m.isEligible);
    return matchesSearch && matchesFilter;
  });

  return (
    <div className="flex min-h-screen bg-slate-950 text-slate-50">
      <Sidebar />
      
      <main className="flex-1 p-8 overflow-y-auto">
        <header className="mb-10 flex justify-between items-end">
          <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
            <h1 className="text-4xl font-black tracking-tighter text-white uppercase italic">Reward Eligibility</h1>
            <p className="text-slate-400 mt-2 font-medium italic">Tactical mapping of points vs. internal marks thresholds.</p>
          </motion.div>
          <button 
            onClick={() => fetchStatus()}
            className="p-3 bg-slate-900 border border-slate-800 rounded-2xl text-slate-400 hover:text-white hover:border-slate-700 transition-all active:scale-95"
          >
            <RefreshCcw size={20} />
          </button>
        </header>

        {/* Targets Grid */}
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 mb-10">
          {Object.entries(yearlyTargets).map(([year, val]: any, i) => (
            <motion.div 
              key={year}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: i * 0.05 }}
              className="bg-slate-900 border border-slate-800 p-4 rounded-2xl group hover:border-blue-500/30 transition-all text-center"
            >
              <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest mb-1">Year {year}</p>
              <p className="text-2xl font-black text-white">{val}</p>
              <p className="text-[8px] font-bold text-blue-500 uppercase mt-1">Average Target</p>
            </motion.div>
          ))}
        </div>

        {/* Global Summary */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
           <SummaryCard 
              label="Ready for Internals" 
              value={summary.eligibleCount} 
              icon={<CheckCircle2 size={24} className="text-emerald-500" />}
              color="emerald"
           />
           <SummaryCard 
              label="Below Threshold" 
              value={summary.belowAverageCount} 
              icon={<AlertCircle size={24} className="text-orange-500" />}
              color="orange"
           />
           <SummaryCard 
              label="Team Reach" 
              value={summary.totalUsers} 
              icon={<Users size={24} className="text-blue-500" />}
              color="blue"
           />
        </div>

        {/* Main List Section */}
        <div className="bg-slate-900 border border-slate-800 rounded-[2.5rem] overflow-hidden backdrop-blur-xl">
           <div className="p-8 border-b border-slate-800 flex flex-col md:flex-row md:items-center justify-between gap-6">
              <div className="relative flex-1 max-w-md">
                 <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
                 <input 
                    type="text" 
                    placeholder="Search by name or register number..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl py-3 pl-12 pr-4 text-sm text-white focus:outline-none focus:border-blue-500/50 transition-all"
                 />
              </div>
              <div className="flex bg-slate-950 p-1 rounded-xl border border-slate-800">
                 {(['ALL', 'ELIGIBLE', 'BELOW'] as const).map((t) => (
                    <button
                       key={t}
                       onClick={() => setFilter(t)}
                       className={cn(
                          "px-6 py-2 rounded-lg text-[10px] font-black uppercase tracking-widest transition-all",
                          filter === t ? "bg-blue-600 text-white shadow-lg shadow-blue-600/20" : "text-slate-500 hover:text-slate-300"
                       )}
                    >
                       {t}
                    </button>
                 ))}
              </div>
           </div>

           <div className="p-4 overflow-x-auto">
              <table className="w-full text-left border-separate border-spacing-y-3">
                 <thead>
                    <tr className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">
                       <th className="px-6 py-2">Engineering Agent</th>
                       <th className="px-6 py-2 text-center">Year</th>
                       <th className="px-6 py-2 text-right">Reward Points</th>
                       <th className="px-6 py-2 text-right">Target Pulse</th>
                       <th className="px-6 py-2 text-center">Eligibility Status</th>
                       <th className="px-6 py-2 text-right">Requirement</th>
                    </tr>
                 </thead>
                 <tbody>
                    <AnimatePresence mode='popLayout'>
                       {filteredMembers.map((m: any, i: number) => (
                          <motion.tr 
                             layout
                             initial={{ opacity: 0, y: 20 }}
                             animate={{ opacity: 1, y: 0 }}
                             exit={{ opacity: 0, scale: 0.95 }}
                             transition={{ delay: i * 0.02 }}
                             key={m.id} 
                             className="group hover:scale-[1.01] transition-transform duration-200"
                          >
                             <td className="px-6 py-4 bg-slate-950/50 border-y border-l border-slate-800 rounded-l-2xl group-hover:border-slate-700">
                                <div className="flex items-center gap-3">
                                   <div className="h-10 w-10 bg-slate-800 rounded-xl border border-slate-700 flex items-center justify-center font-black text-slate-500 group-hover:border-blue-500/30 transition-all overflow-hidden">
                                      {m.profileImageUrl ? <img src={m.profileImageUrl} alt="" className="h-full w-full object-cover" /> : m.name[0]}
                                   </div>
                                   <div>
                                      <p className="text-sm font-bold text-white transition-colors">{m.name}</p>
                                      <p className="text-[10px] font-black text-slate-600 uppercase tracking-widest">{m.regNo}</p>
                                   </div>
                                </div>
                             </td>
                             <td className="px-6 py-4 bg-slate-950/50 border-y border-slate-800 text-center font-black text-slate-400 group-hover:border-slate-700">
                                {m.year}
                             </td>
                             <td className="px-6 py-4 bg-slate-950/50 border-y border-slate-800 text-right group-hover:border-slate-700">
                                <span className={cn("text-lg font-black", m.isEligible ? "text-emerald-500" : "text-orange-500")}>
                                   {m.rewardPoints}
                                </span>
                             </td>
                             <td className="px-6 py-4 bg-slate-950/50 border-y border-slate-800 text-right font-bold text-slate-500 group-hover:border-slate-700">
                                {m.target}
                             </td>
                             <td className="px-6 py-4 bg-slate-950/50 border-y border-slate-800 text-center group-hover:border-slate-700">
                                <div className={cn(
                                   "inline-flex items-center gap-2 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-tighter border",
                                   m.isEligible ? "bg-emerald-500/10 text-emerald-500 border-emerald-500/20" : "bg-orange-500/10 text-orange-500 border-orange-500/20"
                                )}>
                                   {m.isEligible ? <CheckCircle2 size={12} /> : <Calculator size={12} />}
                                   {m.isEligible ? 'Eligible' : 'Below Multiplier'}
                                </div>
                             </td>
                             <td className="px-6 py-4 bg-slate-950/50 border-y border-r border-slate-800 rounded-r-2xl text-right group-hover:border-slate-700">
                                {m.isEligible ? (
                                   <div className="flex items-center justify-end gap-1 text-emerald-500 font-black text-xs">
                                      <ArrowUpRight size={14} />
                                      PASS
                                   </div>
                                ) : (
                                   <span className="text-orange-500/80 font-black text-xs">+{m.pointsNeeded} needed</span>
                                )}
                             </td>
                          </motion.tr>
                       ))}
                    </AnimatePresence>
                 </tbody>
              </table>
           </div>
        </div>
      </main>
    </div>
  );
}

function SummaryCard({ label, value, icon, color }: { label: string, value: any, icon: React.ReactNode, color: string }) {
  const colors: any = {
    emerald: "border-emerald-500/20 bg-emerald-500/5",
    orange: "border-orange-500/20 bg-orange-500/5",
    blue: "border-blue-500/20 bg-blue-500/5",
  };

  return (
    <div className={cn("p-8 rounded-[2rem] border backdrop-blur-xl flex items-center justify-between", colors[color])}>
       <div>
          <p className="text-4xl font-black text-white mb-1">{value}</p>
          <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest">{label}</p>
       </div>
       <div className="h-12 w-12 bg-slate-950 border border-slate-800 rounded-2xl flex items-center justify-center shadow-2xl">
          {icon}
       </div>
    </div>
  );
}
