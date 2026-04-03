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
  FileSpreadsheet
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
import { motion } from 'framer-motion';

const COLORS = ['#888888', '#444444', '#666666', '#AAAAAA', '#222222'];

export default function Dashboard() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [isMounted, setIsMounted] = useState(false);
  const [health, setHealth] = useState<any>({ status: 'ok', database: 'connected' });
  const [syncStatus, setSyncStatus] = useState<any>(null);
  const [showSyncModal, setShowSyncModal] = useState(false);
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
      const res = await api.post('/admin/sync/rewards-sheets');
      if (res.data.success) {
        toast.success('Sync Complete', {
          description: `Updated: ${res.data.data.summary.updated} users.`,
        });
        fetchOverview();
      }
    } catch (err: any) {
      toast.error('Sync Failed');
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
    <div className="flex h-screen bg-[#121212] items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <div className="animate-spin h-8 w-8 border-2 border-[#444444] border-t-[#E0E0E0] rounded-full"></div>
        <p className="text-[#888888] text-[10px] font-black uppercase tracking-[0.3em]">Syncing Core...</p>
      </div>
    </div>
  );

  if (!data) return (
    <div className="flex h-screen bg-[#121212] items-center justify-center">
       <div className="text-center p-8 bg-[#121212] border border-[#444444] rounded-lg shadow-2xl max-w-sm">
          <Activity size={32} className="text-[#888888] mx-auto mb-6" />
          <h2 className="text-xl font-black text-[#E0E0E0] uppercase tracking-tighter">Sync Failed</h2>
          <p className="text-xs text-[#B0B0B0] mt-2 underline decoration-[#444444]">Administrative core disconnected.</p>
          <button onClick={() => window.location.reload()} className="mt-8 px-6 py-3 bg-[#E0E0E0] text-[#121212] text-[10px] font-black uppercase tracking-widest transition-all active:scale-95">
             Retry Protocol
          </button>
       </div>
    </div>
  );

  const roleData = Object.entries(data.roleDistribution || {}).map(([name, value]) => ({ name, value })) as any[];
  const taskData = Object.entries(data.tasks?.byStatus || {}).map(([name, value]) => ({ name, value })) as any[];

  return (
    <div className="flex flex-col lg:flex-row min-h-screen bg-[#121212] text-[#E0E0E0]">
      <Sidebar />

      {/* SYNC MODAL */}
      {showSyncModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-black/60 backdrop-blur-sm">
          <motion.div 
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="w-full max-w-lg bg-[#121212] border border-[#444444] rounded-lg p-10 shadow-2xl text-center"
          >
            <ShieldCheck size={32} className="text-[#E0E0E0] mx-auto mb-6" />
            <h2 className="text-2xl font-black uppercase italic tracking-tighter mb-2 text-[#E0E0E0]">Sync Interrupted</h2>
            <p className="text-[#B0B0B0] text-xs leading-relaxed mb-8">Manual override required for system benchmarks.</p>
            
            <div className="flex gap-4">
              <button onClick={() => setShowSyncModal(false)} className="flex-1 py-4 bg-[#E0E0E0] text-[#121212] text-[10px] font-black uppercase tracking-widest active:scale-95">
                Acknowledge
              </button>
            </div>
          </motion.div>
        </div>
      )}
      
      <main className="flex-1 p-6 md:p-10 overflow-y-auto mt-16 lg:mt-0">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-[#444444] pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h1 className="text-3xl md:text-5xl font-black tracking-tighter text-[#E0E0E0] uppercase italic">TEAM A#100074</h1>
            <p className="text-[#B0B0B0] mt-1 text-[10px] md:text-xs font-bold uppercase tracking-[0.2em] opacity-60">High-fidelity administrative oversight.</p>
          </motion.div>
          <div className="flex gap-3 w-full md:w-auto">
             <button 
                onClick={handleExportActivities}
                className="flex-1 md:flex-none px-4 py-2 bg-transparent border border-[#444444] rounded-md flex items-center justify-center gap-2 hover:bg-[#444444]/20 transition-all font-black text-[10px] uppercase tracking-widest text-[#B0B0B0]"
             >
                <FileSpreadsheet size={14} />
                Export
             </button>
             <button 
                onClick={handleSyncRewards}
                disabled={syncing}
                className="flex-1 md:flex-none px-4 py-2 bg-[#E0E0E0] text-[#121212] rounded-md flex items-center justify-center gap-2 hover:bg-white transition-all font-black text-[10px] uppercase tracking-widest disabled:opacity-50"
             >
                <Zap size={14} className={cn(syncing && "animate-spin")} />
                {syncing ? 'Syncing...' : 'Sync'}
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
          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.5 }} className="bg-transparent border border-[#444444] rounded-lg p-6 md:p-8">
            <h3 className="text-[10px] md:text-xs font-black text-[#888888] mb-8 uppercase tracking-[0.3em] flex items-center gap-2">
               <ShieldCheck size={14} /> Hierarchy
            </h3>
            <div className="h-[200px] w-full">
              {isMounted && (
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={roleData} innerRadius={60} outerRadius={80} paddingAngle={4} dataKey="value">
                      {roleData.map((_, index) => <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />)}
                    </Pie>
                    <Tooltip contentStyle={{ backgroundColor: '#121212', border: '1px solid #444444', borderRadius: '4px', fontSize: '10px', color: '#E0E0E0' }} />
                  </PieChart>
                </ResponsiveContainer>
              )}
            </div>
          </motion.div>

          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.6 }} className="lg:col-span-2 bg-transparent border border-[#444444] rounded-lg p-6 md:p-8">
            <h3 className="text-[10px] md:text-xs font-black text-[#888888] mb-8 uppercase tracking-[0.3em] flex items-center gap-2">
               <Target size={14} /> Operational Velocity
            </h3>
            <div className="h-[200px] w-full">
              {isMounted && (
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={taskData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#444444" vertical={false} />
                    <XAxis dataKey="name" stroke="#888888" fontSize={10} axisLine={false} tickLine={false} />
                    <YAxis stroke="#888888" fontSize={10} axisLine={false} tickLine={false} />
                    <Tooltip cursor={{ fill: '#44444433' }} contentStyle={{ backgroundColor: '#121212', border: '1px solid #444444', borderRadius: '4px' }} />
                    <Bar dataKey="value" fill="#888888" radius={[2, 2, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </div>
          </motion.div>
        </div>

        {/* Bottom Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
           <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.7 }} className="border border-[#444444] rounded-lg p-6 md:p-8">
            <h3 className="text-[10px] md:text-xs font-black text-[#888888] mb-8 uppercase tracking-[0.3em] flex items-center gap-2">
               <Zap size={14} /> Impact Agents
            </h3>
            <div className="space-y-4">
               {data.topPerformers?.length > 0 ? data.topPerformers.map((performer: any, i: number) => (
                 <div key={performer.id} className="flex items-center justify-between p-4 bg-[#444444]/5 border border-[#444444] rounded-md group hover:bg-[#444444]/10 transition-all">
                    <div className="flex items-center gap-4">
                       <span className="text-[10px] font-black text-[#444444] w-4">{i + 1}</span>
                       <div className="h-8 w-8 bg-[#121212] border border-[#444444] rounded-md flex items-center justify-center font-bold text-[#E0E0E0] text-xs">
                          {performer.name?.[0] || '?'}
                       </div>
                       <div>
                          <p className="text-xs font-black text-[#E0E0E0] uppercase tracking-tighter">{performer.name}</p>
                          <p className="text-[9px] font-bold text-[#888888] uppercase">{performer.role}</p>
                       </div>
                    </div>
                    <div className="text-right">
                       <p className="text-xs font-black text-[#E0E0E0]">{performer.activityPoints || 0} APT</p>
                    </div>
                 </div>
               )) : <p className="text-[10px] text-[#444444] text-center py-4 uppercase font-black tracking-widest">No Records</p>}
            </div>
          </motion.div>

           <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.8 }} className="border border-[#444444] rounded-lg p-6 md:p-8">
            <div className="flex items-center justify-between mb-8">
              <h3 className="text-[10px] md:text-xs font-black text-[#888888] uppercase tracking-[0.3em] flex items-center gap-2">
                 <History size={14} /> System Pulse
              </h3>
              <Link href="/audit" className="text-[9px] font-black text-[#E0E0E0] uppercase tracking-widest hover:underline decoration-[#444444]">
                Audit Trail
              </Link>
            </div>
            <div className="space-y-6 relative box-border">
               {data.recentActivities?.length > 0 ? data.recentActivities.map((activity: any) => (
                 <div key={activity.id} className="flex gap-4 group">
                    <div className="flex flex-col items-center">
                       <div className="h-8 w-8 bg-[#121212] border border-[#444444] rounded-md flex items-center justify-center text-[#888888] text-xs transition-all group-hover:border-[#E0E0E0]">
                          <Zap size={12} />
                       </div>
                       <div className="w-px flex-1 bg-[#444444] my-2" />
                    </div>
                    <div className="pb-4">
                       <p className="text-xs font-bold text-[#E0E0E0] leading-snug">
                          <span className="font-black">@{activity.user?.name || 'SYSTEM'}</span> {activity.content}
                       </p>
                       <div className="flex items-center gap-3 mt-1.5 opacity-40">
                          <span className="text-[9px] font-black uppercase tracking-[0.2em]">
                             {new Date(activity.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </span>
                       </div>
                    </div>
                 </div>
               )) : <div className="text-center py-10 text-[#444444] font-black text-[10px] uppercase tracking-[0.3em]">Quiet Pulse</div>}
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
      className="bg-transparent border border-[#444444] p-6 md:p-8 rounded-lg group hover:border-[#888888] transition-all"
    >
      <div className="inline-flex p-2 border border-[#444444] rounded-md mb-4 text-[#888888] group-hover:text-[#E0E0E0] transition-colors">
        {icon}
      </div>
      <div>
        <p className="text-3xl md:text-5xl font-black text-[#E0E0E0] tracking-tighter mb-1">{value}</p>
        <p className="text-[10px] font-black text-[#888888] uppercase tracking-[0.3em]">{title}</p>
      </div>
    </motion.div>
  );
}
