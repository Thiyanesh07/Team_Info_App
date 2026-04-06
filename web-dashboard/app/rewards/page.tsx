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
  const [showSyncModal, setShowSyncModal] = useState(false);
  const [psToken, setPsToken] = useState('');
  const [syncing, setSyncing] = useState(false);

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

  const handleTeamSync = async () => {
    if (!psToken.trim()) {
      toast.error('Token Required', { description: 'Please enter your PS Portal session token.' });
      return;
    }

    try {
      setSyncing(true);
      const res = await api.post('/admin/sync-team-activity', { psToken });
      
      if (res.data.success) {
        toast.success('Batch Sync Successful', {
          description: `Updated ${res.data.updatedCount} members out of ${res.data.total}.`
        });
        setShowSyncModal(false);
        setPsToken('');
        fetchStatus();
      }
    } catch (err: any) {
      console.error('Batch sync error:', err);
      toast.error('Sync Failed', {
        description: err.response?.data?.message || 'Check your portal token and connection.'
      });
    } finally {
      setSyncing(false);
    }
  };

  if (loading) return (
    <div className="flex h-screen bg-[#131313] items-center justify-center">
      <div className="flex flex-col items-center gap-6">
        <div className="h-16 w-16 border-4 border-[#EFD395]/20 border-t-[#EFD395] rounded-full animate-spin"></div>
        <p className="text-[#A4A4A4] text-[10px] font-black uppercase tracking-[0.4em] animate-pulse italic">Calculating Eligibility Matrix</p>
      </div>
    </div>
  );

  const { yearlyTargets, teamStatus, summary } = data || { yearlyTargets: {}, teamStatus: [], summary: {} };

  const filteredMembers = teamStatus.filter((m: any) => {
    const matchesSearch = m.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
                         (m.regNo && m.regNo.toLowerCase().includes(searchQuery.toLowerCase())) ||
                         (m.enrollmentNo && m.enrollmentNo.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesFilter = filter === 'ALL' || 
                         (filter === 'ELIGIBLE' && m.isEligible) || 
                         (filter === 'BELOW' && !m.isEligible);
    return matchesSearch && matchesFilter;
  });

  return (
    <div className="flex min-h-screen bg-[#131313] text-[#FFFFFF]">
      <Sidebar />
      
      <main className="flex-1 p-8 overflow-y-auto custom-scrollbar no-scrollbar">
        <header className="mb-12 border-b border-[#4B4A48] pb-8 flex flex-col md:flex-row justify-between items-start md:items-end gap-6">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h1 className="text-4xl md:text-6xl font-black tracking-tighter text-[#FFFFFF] uppercase italic">Reward Eligibility</h1>
            <p className="text-[#A4A4A4] mt-1 text-[10px] md:text-xs font-black uppercase tracking-[0.2em] opacity-60">Global mapping of points vs. internal marks thresholds.</p>
          </motion.div>
          <div className="flex gap-2">
            <button 
              onClick={() => setShowSyncModal(true)}
              className="px-8 py-3 bg-white text-[#131313] rounded flex items-center justify-center gap-2 hover:bg-[#EFD395] transition-all font-black text-[10px] uppercase tracking-widest shadow-lg active:scale-95"
            >
              <RefreshCcw size={14} />
              Global Activity Sync
            </button>
            <button 
              onClick={() => fetchStatus()}
              className="px-8 py-3 bg-[#EFD395] text-[#131313] rounded flex items-center justify-center gap-2 hover:bg-white transition-all font-black text-[10px] uppercase tracking-widest shadow-lg active:scale-95"
            >
              <ArrowUpRight size={14} />
              Refresh Analytics
            </button>
          </div>
        </header>

        {/* Targets Grid */}
         <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-6 mb-12">
          {Object.entries(yearlyTargets).map(([year, val]: any, i) => (
            <motion.div 
              key={year}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: i * 0.05 }}
              whileHover={{ y: -5 }}
              className="bg-[#262625] border border-[#4B4A48] p-6 rounded group hover:border-[#EFD395]/40 transition-all text-center"
            >
              <p className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.3em] mb-4 opacity-60">Year {year}</p>
              <p className="text-4xl font-black text-white italic group-hover:text-[#EFD395] transition-colors uppercase tracking-tighter">{val}</p>
              <p className="text-[9px] font-black text-[#777674] uppercase mt-4 tracking-[0.2em] italic">Target Index</p>
            </motion.div>
          ))}
        </div>

        {/* Global Summary */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
           <SummaryCard 
              label="Ready for Internals" 
              value={summary.eligibleCount} 
              icon={<CheckCircle2 size={24} className="text-[#EFD395]" />}
              color="straw"
           />
           <SummaryCard 
              label="Below Threshold" 
              value={summary.belowAverageCount} 
              icon={<AlertCircle size={24} className="text-red-500" />}
              color="red"
           />
           <SummaryCard 
              label="Team Reach" 
              value={summary.totalUsers} 
              icon={<Users size={24} className="text-[#A4A4A4]" />}
              color="grey"
           />
        </div>

        {/* Main List Section */}
        <div className="bg-[#262625] border border-[#4B4A48] rounded overflow-hidden shadow-2xl mb-12">
           <div className="p-8 border-b border-[#4B4A48] flex flex-col md:flex-row md:items-center justify-between gap-8 bg-[#131313]/30">
              <div className="relative flex-1 max-w-lg">
                 <Search className="absolute left-5 top-1/2 -translate-y-1/2 text-[#4B4A48]" size={20} />
                 <input 
                    type="text" 
                    placeholder="Search by name or register number..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 pl-14 text-xs text-white focus:outline-none focus:border-[#EFD395] transition-all font-black uppercase italic shadow-inner"
                 />
              </div>
              <div className="flex bg-[#131313] p-1.5 rounded border border-[#4B4A48]">
                 {(['ALL', 'ELIGIBLE', 'BELOW'] as const).map((t) => (
                    <button
                       key={t}
                       onClick={() => setFilter(t)}
                       className={cn(
                          "px-8 py-2.5 rounded text-[10px] font-black uppercase tracking-[0.3em] transition-all italic",
                          filter === t ? "bg-[#EFD395] text-[#131313] shadow-xl" : "text-[#777674] hover:text-[#FFFFFF]"
                       )}
                    >
                       {t}
                    </button>
                 ))}
              </div>
           </div>

           <div className="p-6 overflow-x-auto custom-scrollbar no-scrollbar">
              <table className="w-full text-left border-separate border-spacing-y-4">
                 <thead>
                    <tr className="text-[10px] font-black text-[#777674] uppercase tracking-[0.4em] italic">
                       <th className="px-6 py-4">Engineering Agent</th>
                       <th className="px-6 py-4 text-center">Year</th>
                       <th className="px-6 py-4 text-right">Reward Points</th>
                       <th className="px-6 py-4 text-right">Target Pulse</th>
                       <th className="px-6 py-4 text-center">Eligibility Status</th>
                       <th className="px-6 py-4 text-right">Requirement</th>
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
                             className="group hover:bg-[#131313]/50 transition-colors"
                          >
                             <td className="px-6 py-5 bg-[#131313] border-y border-l border-[#4B4A48] rounded-l group-hover:border-[#EFD395]/40">
                                <div className="flex items-center gap-4">
                                   <div className="h-12 w-12 bg-[#262625] rounded border border-[#4B4A48] flex items-center justify-center font-black text-[#EFD395] group-hover:border-[#EFD395] transition-all overflow-hidden italic shadow-inner">
                                      {m.profileImageUrl ? <img src={m.profileImageUrl} alt="" className="h-full w-full object-cover" /> : m.name[0]}
                                   </div>
                                   <div>
                                      <p className="text-sm font-black text-white uppercase italic tracking-tight">{m.name}</p>
                                      <p className="text-[10px] font-black text-[#777674] uppercase tracking-[0.2em] italic">
                                         {m.regNo || '---'} • {m.enrollmentNo ? `ID: ${m.enrollmentNo}` : 'NO ID'}
                                      </p>
                                   </div>
                                </div>
                             </td>
                             <td className="px-6 py-5 bg-[#131313] border-y border-[#4B4A48] text-center font-black text-[#A4A4A4] group-hover:border-[#EFD395]/40 italic">
                                {m.year}
                             </td>
                             <td className="px-6 py-5 bg-[#131313] border-y border-[#4B4A48] text-right group-hover:border-[#EFD395]/40">
                                <span className={cn("text-xl font-black italic tracking-tighter", m.isEligible ? "text-[#EFD395]" : "text-red-500")}>
                                   {m.rewardPoints}
                                </span>
                             </td>
                             <td className="px-6 py-5 bg-[#131313] border-y border-[#4B4A48] text-right font-black text-[#777674] group-hover:border-[#EFD395]/40 italic">
                                {m.target}
                             </td>
                             <td className="px-6 py-5 bg-[#131313] border-y border-[#4B4A48] text-center group-hover:border-[#EFD395]/40">
                                <div className={cn(
                                   "inline-flex items-center gap-2 px-4 py-1.5 rounded border text-[9px] font-black uppercase tracking-[0.2em] italic",
                                   m.isEligible ? "bg-[#EFD395]/10 text-[#EFD395] border-[#EFD395]/20" : "bg-red-500/10 text-red-500 border-red-500/20"
                                )}>
                                   {m.isEligible ? <CheckCircle2 size={12} /> : <Calculator size={12} />}
                                   {m.isEligible ? 'Eligible' : 'Below Multiplier'}
                                </div>
                             </td>
                             <td className="px-6 py-5 bg-[#131313] border-y border-r border-[#4B4A48] rounded-r text-right group-hover:border-[#EFD395]/40">
                                {m.isEligible ? (
                                   <div className="flex items-center justify-end gap-2 text-[#EFD395] font-black text-[10px] uppercase italic tracking-[0.2em]">
                                      <ArrowUpRight size={16} />
                                      PASS
                                   </div>
                                ) : (
                                   <span className="text-red-500 font-black text-[10px] uppercase italic tracking-[0.2em]">+{m.pointsNeeded} needed</span>
                                )}
                             </td>
                          </motion.tr>
                       ))}
                    </AnimatePresence>
                 </tbody>
              </table>
           </div>
        </div>

        {/* Sync Modal */}
        <AnimatePresence>
          {showSyncModal && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-black/80 backdrop-blur-xl">
              <motion.div 
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.95 }}
                className="relative w-full max-w-md bg-[#262625] border border-[#4B4A48] rounded p-10 shadow-2xl"
              >
                <div className="flex justify-between items-start mb-8">
                  <div>
                    <h3 className="text-2xl font-black text-white uppercase tracking-tighter italic">Batch Portal Sync</h3>
                    <p className="text-[10px] font-black text-[#777674] uppercase tracking-widest mt-1">Sync entire team activity points via PS Portal.</p>
                  </div>
                  <button onClick={() => setShowSyncModal(false)} className="p-2 text-[#777674] hover:text-white transition-colors">
                    <X size={20} />
                  </button>
                </div>

                <div className="space-y-6">
                  <div className="p-4 bg-[#131313] border border-blue-500/20 rounded">
                    <p className="text-[10px] text-blue-400 font-bold uppercase tracking-widest mb-1.5 flex items-center gap-2">
                       <AlertCircle size={12} /> Authentication Required
                    </p>
                    <p className="text-[11px] text-[#A4A4A4] leading-relaxed">
                      Enter your <span className="text-white italic">PS Portal session token</span> to authorize the batch summation. You can find this in your browser cookies as 'PS'.
                    </p>
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-[#777674] ml-1">Portal Session Token</label>
                    <textarea 
                      className="w-full bg-[#131313] border border-[#4B4A48] rounded px-4 py-3.5 text-xs focus:outline-none focus:border-[#EFD395] transition-all font-black text-[#FFFFFF] shadow-inner min-h-[100px]"
                      placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
                      value={psToken}
                      onChange={(e) => setPsToken(e.target.value)}
                    />
                  </div>

                  <button 
                    disabled={syncing}
                    onClick={handleTeamSync}
                    className="w-full py-4 bg-[#EFD395] hover:bg-white text-[#131313] rounded font-black text-[10px] uppercase tracking-widest transition-all shadow-lg active:scale-95 disabled:opacity-50"
                  >
                    {syncing ? 'Processing Core Sync...' : 'Initiate Global Sync'}
                  </button>
                </div>
              </motion.div>
            </div>
          )}
        </AnimatePresence>
      </main>
    </div>
  );
}

const X = ({ size }: { size: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
);

function SummaryCard({ label, value, icon, color }: { label: string, value: any, icon: React.ReactNode, color: string }) {
  const colors: any = {
    straw: "border-[#EFD395]/20 bg-[#EFD395]/5",
    red: "border-red-500/20 bg-red-500/5",
    grey: "border-[#4B4A48]/20 bg-[#4B4A48]/5",
  };

  return (
    <div className={cn("p-10 rounded border flex items-center justify-between group hover:border-white/20 transition-all shadow-xl", colors[color])}>
       <div>
          <p className="text-5xl font-black text-white mb-2 italic tracking-tighter">{value}</p>
          <p className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.3em] group-hover:text-white transition-colors italic">{label}</p>
       </div>
       <div className="h-14 w-14 bg-[#131313] border border-[#4B4A48] rounded flex items-center justify-center shadow-2xl group-hover:border-[#EFD395]/40 transition-colors">
          {icon}
       </div>
    </div>
  );
}
