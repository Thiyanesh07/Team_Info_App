'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import Sidebar from '@/components/Sidebar';
import api, { downloadExcel, checkHealth } from '@/lib/api';
import { toast } from 'sonner';
import { 
  Users, 
  Rocket, 
  CheckCircle, 
  Clock, 
  Activity, 
  TrendingUp, 
  ShieldCheck, 
  Zap,
  Target,
  Trophy,
  History,
  FileSpreadsheet,
  AlertCircle
} from 'lucide-react';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer, 
  PieChart, 
  Pie, 
  Cell
} from 'recharts';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';

const COLORS = ['#EFD395', '#A4A4A4', '#777674', '#4B4A48', '#262625'];

const X = ({ size }: { size: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
);

export default function Dashboard() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [isMounted, setIsMounted] = useState(false);
  const [health, setHealth] = useState<any>({ status: 'ok', database: 'connected' });
  const [syncStatus, setSyncStatus] = useState<any>(null);
  const [showSyncModal, setShowSyncModal] = useState(false);
  const [showPortalModal, setShowPortalModal] = useState(false);
  const [psToken, setPsToken] = useState('');
  const [manualTargets, setManualTargets] = useState<any>([]);

  useEffect(() => {
    setIsMounted(true);
    fetchOverview();
    
    const runHealthCheck = async () => {
      const h = await checkHealth();
      setHealth(h);
    };
    runHealthCheck();

    const checkSyncStatus = async () => {
      try {
        const res = await api.get('/admin/sync-status');
        if (res.data.success) {
          setSyncStatus(res.data.data);
          setManualTargets(res.data.data.details || []);
          if (res.data.data.status === 'FAILED') {
            setShowSyncModal(true);
            toast.error('Sync Interrupted');
          }
        }
      } catch (err) {
        console.error('Sync status check failed:', err);
      }
    };
    checkSyncStatus();

    const interval = setInterval(runHealthCheck, 120000);
    return () => clearInterval(interval);
  }, []);

  const fetchOverview = async () => {
    try {
      const res = await api.get('/admin/overview');
      if (res.data.success) {
        setData(res.data.data);
      }
    } catch (err) {
      console.error('Fetch overview error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSyncRewards = async () => {
    try {
      setSyncing(true);
      const res = await api.post('/admin/sync/rewards');
      if (res.data.success) {
        toast.success('Sync Complete', {
          description: `Successfully synchronized ${res.data.summary?.updatedCount || 0} teammates via HF Hub.`
        });
        fetchOverview();
      }
    } catch (err: any) {
      toast.error('Sync Failed', {
        description: err.response?.data?.message || 'Check connection to Hugging Face Hub.'
      });
    } finally {
      setSyncing(false);
    }
  };

  const handlePortalSync = async () => {
    if (!psToken.trim()) {
      toast.error('Token Required');
      return;
    }
    try {
      setSyncing(true);
      const res = await api.post('/admin/sync-team-activity', { psToken });
      if (res.data.success) {
        toast.success('Portal Sync Complete', {
          description: `Updated ${res.data.updatedCount} members via PS Portal breakdown summation.`
        });
        setShowPortalModal(false);
        setPsToken('');
        fetchOverview();
      }
    } catch (err: any) {
      toast.error('Portal Sync Failed');
    } finally {
      setSyncing(false);
    }
  };

  const handleExportActivities = async () => {
    try {
      toast.info('Generating... ');
      await downloadExcel('/export/activities', `Activities_${Date.now()}.xlsx`, { scope: 'TEAM' });
      toast.success('Downloaded');
    } catch (err: any) {
      toast.error('Export Failed');
    }
  };

  if (loading) return (
    <div className="flex h-screen bg-[#131313] items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <div className="animate-spin h-8 w-8 border-2 border-[#4B4A48] border-t-[#EFD395] rounded-full"></div>
        <p className="text-[#A4A4A4] text-[10px] font-black uppercase tracking-[0.3em]">Syncing Core...</p>
      </div>
    </div>
  );

  if (!data) return (
    <div className="flex h-screen bg-[#131313] items-center justify-center">
       <div className="text-center p-8 bg-[#262625] border border-[#4B4A48] rounded shadow-2xl max-sm">
          <Activity size={32} className="text-[#777674] mx-auto mb-6" />
          <h2 className="text-xl font-black text-[#FFFFFF] uppercase tracking-tighter italic">Sync Failed</h2>
          <p className="text-xs text-[#A4A4A4] mt-2 underline decoration-[#4B4A48]">Administrative core disconnected.</p>
          <button onClick={() => window.location.reload()} className="mt-8 px-6 py-3 bg-[#EFD395] text-[#131313] text-[10px] font-black uppercase tracking-widest transition-all active:scale-95">
             Retry Protocol
          </button>
       </div>
    </div>
  );

  const roleData = Object.entries(data.roleDistribution || {}).map(([name, value]) => ({ name, value })) as any[];
  const taskData = Object.entries(data.tasks?.byStatus || {}).map(([name, value]) => ({ name, value })) as any[];

  return (
    <div className="flex flex-col lg:flex-row min-h-screen bg-[#131313] text-[#FFFFFF]">
      <Sidebar />

      <AnimatePresence>
        {/* SYNC INTERRUPTED MODAL */}
        {showSyncModal && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-black/80 backdrop-blur-md">
            <motion.div 
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="w-full max-w-lg bg-[#262625] border border-[#4B4A48] rounded p-10 shadow-2xl text-center"
            >
              <ShieldCheck size={32} className="text-[#EFD395] mx-auto mb-6" />
              <h2 className="text-2xl font-black uppercase italic tracking-tighter mb-2 text-[#FFFFFF]">Sync Interrupted</h2>
              <p className="text-[#A4A4A4] text-xs leading-relaxed mb-8">Manual override required for system benchmarks.</p>
              
              <div className="flex gap-4">
                <button onClick={() => setShowSyncModal(false)} className="flex-1 py-4 bg-[#EFD395] text-[#131313] text-[10px] font-black uppercase tracking-widest active:scale-95">
                  Acknowledge
                </button>
              </div>
            </motion.div>
          </div>
        )}

        {/* PORTAL SYNC MODAL */}
        {showPortalModal && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-black/80 backdrop-blur-md">
            <motion.div 
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="w-full max-w-lg bg-[#262625] border border-[#4B4A48] rounded p-10 shadow-2xl"
            >
              <div className="flex justify-between items-start mb-6">
                <h2 className="text-2xl font-black uppercase italic tracking-tighter text-[#FFFFFF]">Activity Sync</h2>
                <button onClick={() => setShowPortalModal(false)} className="text-[#777674] hover:text-white transition-colors">
                  <X size={20} />
                </button>
              </div>
              <p className="text-[#A4A4A4] text-xs leading-relaxed mb-6">Authorize batch summation of activity points from the college portal.</p>
              
              <div className="space-y-4">
                <textarea 
                  className="w-full bg-[#131313] border border-[#4B4A48] rounded px-4 py-3.5 text-xs text-white focus:border-[#EFD395] outline-none min-h-[100px] font-mono"
                  placeholder="Paste PS Token here..."
                  value={psToken}
                  onChange={(e) => setPsToken(e.target.value)}
                />
                <button 
                  onClick={handlePortalSync}
                  disabled={syncing}
                  className="w-full py-4 bg-[#EFD395] text-[#131313] text-[10px] font-black uppercase tracking-widest active:scale-95 disabled:opacity-50"
                >
                  {syncing ? 'Processing...' : 'Run Global AP Sync'}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
      
      <main className="flex-1 p-6 md:p-10 overflow-y-auto mt-16 lg:mt-0 custom-scrollbar no-scrollbar">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-[#4B4A48] pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h1 className="text-3xl md:text-5xl font-black tracking-tighter text-[#FFFFFF] uppercase italic">TEAM A#100074</h1>
            <p className="text-[#A4A4A4] mt-1 text-[10px] md:text-xs font-bold uppercase tracking-[0.2em] opacity-60">High-fidelity administrative oversight.</p>
          </motion.div>
          <div className="flex gap-3 w-full md:w-auto">
             <button 
                onClick={handleExportActivities}
                className="flex-1 md:flex-none px-4 py-2 bg-transparent border border-[#4B4A48] rounded flex items-center justify-center gap-2 hover:bg-[#EFD395]/10 transition-all font-black text-[10px] uppercase tracking-widest text-[#A4A4A4]"
             >
                <FileSpreadsheet size={14} />
                Export
             </button>
              <button 
                onClick={handleSyncRewards}
                disabled={syncing}
                className="flex-1 md:flex-none px-4 py-2 bg-[#EFD395] text-[#131313] rounded flex items-center justify-center gap-2 hover:bg-white transition-all font-black text-[10px] uppercase tracking-widest disabled:opacity-50"
                title="Sync Reward Points via HF Hub"
              >
                <Trophy size={14} className={cn(syncing && "animate-spin")} />
                Sync RP
              </button>
              <button 
                onClick={() => setShowPortalModal(true)}
                disabled={syncing}
                className="flex-1 md:flex-none px-4 py-2 bg-white text-[#131313] rounded flex items-center justify-center gap-2 hover:bg-[#EFD395] transition-all font-black text-[10px] uppercase tracking-widest disabled:opacity-50"
                title="Sync Activity Points via PS Portal"
              >
                <Zap size={14} />
                Sync AP
              </button>
          </div>
        </header>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6 mb-12">
          <StatCard title="Accounts" value={data.totalUsers || 0} icon={<Users size={18} />} delay={0.1} />
          <StatCard title="Projects" value={data.projects?.total || 0} icon={<Rocket size={18} />} delay={0.2} />
          <StatCard title="Tasks" value={data.tasks?.total || 0} icon={<CheckCircle size={18} />} delay={0.3} />
          <StatCard title="Outcomes" value={(data.counts?.hackathons || 0) + (data.counts?.learnings || 0)} icon={<Trophy size={18} />} delay={0.4} />
        </div>

        {/* Charts Section */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-12">
          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.5 }} className="bg-[#262625] border border-[#4B4A48] rounded p-6 md:p-8">
            <h3 className="text-[10px] md:text-xs font-black text-[#A4A4A4] mb-8 uppercase tracking-[0.3em] flex items-center gap-2">
               <ShieldCheck size={14} /> Hierarchy
            </h3>
            <div className="h-[200px] w-full">
              {isMounted && (
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={roleData} innerRadius={60} outerRadius={80} paddingAngle={4} dataKey="value">
                      {roleData.map((_, index) => <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} stroke="none" />)}
                    </Pie>
                    <Tooltip contentStyle={{ backgroundColor: '#262625', border: '1px solid #4B4A48', borderRadius: '4px', fontSize: '10px', color: '#FFFFFF' }} labelStyle={{ display: 'none' }} />
                  </PieChart>
                </ResponsiveContainer>
              )}
            </div>
          </motion.div>

          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.6 }} className="lg:col-span-2 bg-[#262625] border border-[#4B4A48] rounded p-6 md:p-8">
            <h3 className="text-[10px] md:text-xs font-black text-[#A4A4A4] mb-8 uppercase tracking-[0.3em] flex items-center gap-2">
               <Target size={14} /> Operational Velocity
            </h3>
            <div className="h-[200px] w-full">
              {isMounted && (
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={taskData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#4B4A48" vertical={false} />
                    <XAxis dataKey="name" stroke="#777674" fontSize={10} axisLine={false} tickLine={false} />
                    <YAxis stroke="#777674" fontSize={10} axisLine={false} tickLine={false} />
                    <Tooltip cursor={{ fill: '#4B4A4833' }} contentStyle={{ backgroundColor: '#262625', border: '1px solid #4B4A48', borderRadius: '4px' }} />
                    <Bar dataKey="value" fill="#EFD395" radius={[2, 2, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </div>
          </motion.div>
        </div>

        {/* Bottom Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
           <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.7 }} className="bg-[#262625] border border-[#4B4A48] rounded p-6 md:p-8">
            <h3 className="text-[10px] md:text-xs font-black text-[#A4A4A4] mb-8 uppercase tracking-[0.3em] flex items-center gap-2">
               <Zap size={14} /> Impact Agents
            </h3>
            <div className="space-y-4">
               {data.topPerformers?.length > 0 ? data.topPerformers.map((performer: any, i: number) => (
                 <div key={performer.id} className="flex items-center justify-between p-4 bg-[#131313] border border-[#4B4A48] rounded group hover:bg-[#4B4A48]/10 transition-all">
                    <div className="flex items-center gap-4">
                       <span className="text-[10px] font-black text-[#777674] w-4">{i + 1}</span>
                       <div className="h-8 w-8 bg-[#262625] border border-[#4B4A48] rounded flex items-center justify-center font-bold text-[#FFFFFF] text-xs">
                          {performer.name?.[0] || '?'}
                       </div>
                       <div>
                          <p className="text-xs font-black text-[#FFFFFF] uppercase tracking-tighter italic">{performer.name}</p>
                          <p className="text-[9px] font-bold text-[#A4A4A4] uppercase">{performer.role}</p>
                       </div>
                    </div>
                    <div className="text-right">
                       <p className="text-xs font-black text-[#EFD395]">{performer.activityPoints || 0} APT</p>
                    </div>
                 </div>
               )) : <p className="text-[10px] text-[#777674] text-center py-4 uppercase font-black tracking-widest">No Records</p>}
            </div>
          </motion.div>

           <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.8 }} className="bg-[#262625] border border-[#4B4A48] rounded p-6 md:p-8">
            <div className="flex items-center justify-between mb-8">
              <h3 className="text-[10px] md:text-xs font-black text-[#A4A4A4] uppercase tracking-[0.3em] flex items-center gap-2">
                 <History size={14} /> System Pulse
              </h3>
              <Link href="/audit" className="text-[9px] font-black text-[#EFD395] uppercase tracking-widest hover:underline decoration-[#4B4A48]">
                Audit Trail
              </Link>
            </div>
            <div className="space-y-6 relative box-border">
               {data.recentActivities?.length > 0 ? data.recentActivities.map((activity: any) => (
                 <div key={activity.id} className="flex gap-4 group">
                    <div className="flex flex-col items-center">
                       <div className="h-8 w-8 bg-[#131313] border border-[#4B4A48] rounded flex items-center justify-center text-[#777674] text-xs transition-all group-hover:border-[#EFD395]">
                          <Zap size={12} />
                       </div>
                       <div className="w-px flex-1 bg-[#4B4A48] my-2" />
                    </div>
                    <div className="pb-4">
                       <p className="text-xs font-bold text-[#FFFFFF] leading-snug">
                          <span className="font-black text-[#EFD395]">@{activity.user?.name || 'SYSTEM'}</span> {activity.content}
                       </p>
                       <div className="flex items-center gap-3 mt-1.5 opacity-40">
                          <span className="text-[9px] font-black uppercase tracking-[0.2em] text-[#A4A4A4]">
                             {new Date(activity.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </span>
                       </div>
                    </div>
                 </div>
               )) : <div className="text-center py-10 text-[#777674] font-black text-[10px] uppercase tracking-[0.3em]">Quiet Pulse</div>}
            </div>
          </motion.div>
        </div>
      </main>
    </div>
  );
}

function StatCard({ title, value, icon, delay }: { title: string, value: any, icon: React.ReactNode, delay: number }) {
  return (
    <motion.div 
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1 }}
      transition={{ delay }}
      className="bg-[#262625] border border-[#4B4A48] p-6 md:p-8 rounded group hover:border-[#EFD395]/50 transition-all shadow-lg"
    >
      <div className="inline-flex p-2 border border-[#4B4A48] rounded mb-4 text-[#777674] group-hover:text-[#EFD395] transition-colors bg-[#131313]">
        {icon}
      </div>
      <div>
        <p className="text-3xl md:text-5xl font-black text-[#FFFFFF] tracking-tighter mb-1 italic">{value}</p>
        <p className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.3em]">{title}</p>
      </div>
    </motion.div>
  );
}
