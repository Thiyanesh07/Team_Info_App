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
  Cell,
  AreaChart,
  Area
} from 'recharts';
import { cn } from '@/lib/utils';
import { motion } from 'framer-motion';

const COLORS = ['#3b82f6', '#f59e0b', '#ef4444', '#10b981', '#8b5cf6'];

export default function Dashboard() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [isMounted, setIsMounted] = useState(false);
  const [health, setHealth] = useState<any>({ status: 'ok', database: 'connected' });
  const [syncStatus, setSyncStatus] = useState<any>(null);
  const [showSyncModal, setShowSyncModal] = useState(false);
  const [editingTargets, setEditingTargets] = useState(false);
  const [manualTargets, setManualTargets] = useState<any>([]);

  useEffect(() => {
    setIsMounted(true);
    fetchOverview();
    
    // Initial health check
    const runHealthCheck = async () => {
      const h = await checkHealth();
      setHealth(h);
    };
    runHealthCheck();

    // Check Sync Status and trigger Alert if failed
    const checkSyncStatus = async () => {
      try {
        const res = await api.get('/admin/sync-status');
        if (res.data.success) {
          setSyncStatus(res.data.data);
          setManualTargets(res.data.data.details || []);
          if (res.data.data.status === 'FAILED') {
            setShowSyncModal(true);
            toast.error('Sync Interrupted', {
              description: 'The automated benchmark scraper was blocked by Google security.',
              duration: 10000,
            });
          }
        }
      } catch (err) {
        console.error('Sync status check failed:', err);
      }
    };
    checkSyncStatus();

    // Periodic health check every 2 minutes
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
        toast.success('Synchronization Complete', {
          description: `Updated: ${res.data.data.summary.updated} users. Not matched: ${res.data.data.summary.notFound}.`,
          duration: 5000,
        });
        fetchOverview();
      }
    } catch (err: any) {
      console.error('Sync error:', err);
      toast.error('Synchronization Failed', {
        description: err.response?.data?.message || 'Check backend logs for details.',
      });
    } finally {
      setSyncing(false);
    }
  };

  const handleExportActivities = async () => {
    try {
      toast.info('Generating Activity Report...');
      await downloadExcel('/export/activities', `Team_Activities_${new Date().getTime()}.xlsx`, { scope: 'TEAM' });
      toast.success('Activity Report Downloaded');
    } catch (err: any) {
      toast.error('Export Failed', { description: 'Failed to generate activities report.' });
    }
  };

  const handleUpdateTargets = async () => {
    try {
      setSyncing(true);
      const res = await api.patch('/admin/manage/yearly-targets', {
        targets: manualTargets.map((t: any) => ({ year: t.year, target: t.target }))
      });
      if (res.data.success) {
        toast.success('Benchmarks Updated Successfully');
        setEditingTargets(false);
        setShowSyncModal(false);
      }
    } catch (err: any) {
      toast.error('Update Failed', { description: 'Failed to manually override benchmarks.' });
    } finally {
      setSyncing(false);
    }
  };

  if (loading) return (
    <div className="flex h-screen bg-slate-950 items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500 shadow-lg shadow-blue-500/20"></div>
        <p className="text-slate-500 text-xs font-black uppercase tracking-[0.3em] animate-pulse">Initializing Pulse Core</p>
      </div>
    </div>
  );

  if (!data) return (
    <div className="flex h-screen bg-slate-950 items-center justify-center">
       <div className="text-center p-8 bg-slate-900 border border-slate-800 rounded-[2.5rem] shadow-2xl max-w-sm">
          <div className="h-20 w-20 bg-rose-500/10 border border-rose-500/20 rounded-3xl flex items-center justify-center mx-auto mb-6">
             <Activity size={32} className="text-rose-500" />
          </div>
          <h2 className="text-xl font-black text-white">Interface Sync Failed</h2>
          <p className="text-sm text-slate-500 mt-2 leading-relaxed">The administrative core could not establish a connection to the dashboard services.</p>
          <button onClick={() => window.location.reload()} className="mt-8 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl text-xs font-black uppercase tracking-widest text-white transition-all shadow-lg shadow-blue-600/20 active:scale-95">
             Retry Protocol
          </button>
       </div>
    </div>
  );

  const roleDistribution = data.roleDistribution || {};
  const tasksByStatus = data.tasks?.byStatus || {};

  const roleData = Object.entries(roleDistribution).map(([name, value]) => ({ name, value })) as { name: string, value: number }[];
  const taskData = Object.entries(tasksByStatus).map(([name, value]) => ({ name, value })) as { name: string, value: number }[];

  return (
    <div className="flex min-h-screen bg-slate-950 text-slate-50">
      <Sidebar />

      {/* SYNC FAILURE POPUP */}
      {showSyncModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-md">
          <motion.div 
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="w-full max-w-xl bg-slate-900 border border-slate-800 rounded-[3rem] p-10 shadow-3xl text-center relative overflow-hidden"
          >
            <div className="absolute top-0 right-0 p-10 opacity-5">
              <Zap size={150} className="text-rose-500" />
            </div>

            <div className="h-20 w-20 bg-rose-500/10 border border-rose-500/20 rounded-3xl flex items-center justify-center mx-auto mb-8 animate-pulse">
               <ShieldCheck size={32} className="text-rose-500" />
            </div>

            <h2 className="text-3xl font-black text-white italic tracking-tighter uppercase mb-2">Sync Decoupled</h2>
            <p className="text-slate-400 text-sm leading-relaxed mb-8 max-w-md mx-auto">
              The automated benchmarking service encountered a security challenge from Google (likely a CAPTCHA). 
              <br/><br/>
              <span className="text-rose-400 font-bold">Error:</span> {syncStatus?.error || 'Unknown Scraper Error'}
            </p>

            <div className="space-y-4">
              <div className="grid grid-cols-3 gap-4 mb-8">
                {manualTargets.map((t: any, idx: number) => (
                  <div key={t.year} className="bg-slate-950 p-4 rounded-2xl border border-slate-800">
                    <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest mb-1">Year {t.year}</p>
                    <input 
                      type="number"
                      value={t.target}
                      onChange={(e) => {
                        const newTargets = [...manualTargets];
                        newTargets[idx].target = parseFloat(e.target.value);
                        setManualTargets(newTargets);
                      }}
                      className="w-full bg-transparent text-lg font-black text-white text-center focus:outline-none focus:text-blue-400 transition-colors"
                    />
                  </div>
                ))}
              </div>

              <div className="flex gap-4">
                <button 
                  onClick={handleUpdateTargets}
                  className="flex-1 py-4 bg-blue-600 hover:bg-blue-500 rounded-2xl text-xs font-black uppercase tracking-widest text-white transition-all shadow-lg shadow-blue-600/20 active:scale-95"
                >
                  Confirm Manual Override
                </button>
                <button 
                  onClick={() => setShowSyncModal(false)}
                  className="px-8 py-4 bg-slate-800 hover:bg-slate-700 rounded-2xl text-xs font-black uppercase tracking-widest text-slate-300 transition-all border border-slate-700"
                >
                  Dismiss
                </button>
              </div>
              <p className="text-[9px] font-bold text-slate-500 uppercase tracking-[0.2em] mt-6">
                Last Successful Sync: {syncStatus?.lastSync ? new Date(syncStatus.lastSync).toLocaleString() : 'Never'}
              </p>
            </div>
          </motion.div>
        </div>
      )}
      
      <main className="flex-1 p-8 overflow-y-auto">
        <header className="mb-10 flex justify-between items-end">
          <motion.div 
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
          >
            <h1 className="text-4xl font-black tracking-tighter text-white uppercase italic">Engineering Pulse</h1>
            <p className="text-slate-400 mt-2 font-medium italic">High-fidelity administrative oversight and tactical system health.</p>
          </motion.div>
          <div className="flex gap-3">
             <button 
                onClick={handleExportActivities}
                className="px-4 py-2 bg-emerald-500/10 border border-emerald-500/20 rounded-2xl flex items-center gap-2 hover:bg-emerald-600/20 transition-all active:scale-95 group"
             >
                <FileSpreadsheet size={14} className="text-emerald-500 group-hover:scale-110 transition-transform" />
                <span className="text-xs font-bold text-emerald-400 uppercase tracking-widest">
                  Export Activities
                </span>
             </button>
             <button 
                onClick={handleSyncRewards}
                disabled={syncing}
                className={cn(
                  "px-4 py-2 bg-blue-600/10 border border-blue-500/20 rounded-2xl flex items-center gap-2 hover:bg-blue-600/20 transition-all active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed",
                  syncing && "animate-pulse"
                )}
             >
                <Activity size={14} className={cn("text-blue-500", syncing && "animate-spin")} />
                <span className="text-xs font-bold text-blue-400 uppercase tracking-widest">
                  {syncing ? 'Syncing...' : 'Sync Rewards'}
                </span>
             </button>
             <div className={cn(
                "px-4 py-2 border rounded-2xl flex items-center gap-2 transition-colors",
                health.database === 'connected' 
                  ? "bg-emerald-500/10 border-emerald-500/20" 
                  : "bg-rose-500/10 border-rose-500/20"
              )}>
                <div className={cn(
                  "h-2 w-2 rounded-full animate-pulse",
                  health.database === 'connected' ? "bg-emerald-500" : "bg-rose-500"
                )} />
                <span className={cn(
                  "text-xs font-bold uppercase tracking-widest",
                  health.database === 'connected' ? "text-emerald-500" : "text-rose-500"
                )}>
                  {health.database === 'connected' ? 'Pulse Online' : 'Core Disconnect'}
                </span>
             </div>
          </div>
        </header>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
          <StatCard title="Total Accounts" value={data.totalUsers || 0} icon={<Users className="text-blue-500" />} trend="+12% from last month" color="blue" delay={0.1} />
          <StatCard title="Active Projects" value={data.projects?.total || 0} icon={<Rocket className="text-amber-500" />} trend="4 ongoing cycles" color="amber" delay={0.2} />
          <StatCard title="Tasks Managed" value={data.tasks?.total || 0} icon={<CheckCircle className="text-emerald-500" />} trend="82% completion rate" color="emerald" delay={0.3} />
          <StatCard title="Total Outcomes" value={(data.counts?.hackathons || 0) + (data.counts?.learnings || 0)} icon={<Trophy className="text-purple-500" />} trend="New milestones reached" color="purple" delay={0.4} />
        </div>

        {/* Charts Section */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-10">
          {/* Role Distribution */}
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5 }}
            className="lg:col-span-1 bg-slate-900 border border-slate-800 rounded-3xl p-8 backdrop-blur-xl"
          >
            <h3 className="text-lg font-black text-white mb-6 flex items-center gap-2">
               <ShieldCheck size={20} className="text-blue-500" />
               Hierarchy Mapping
            </h3>
            <div className="h-[250px] w-full">
              {isMounted && (
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={roleData}
                      innerRadius={60}
                      outerRadius={80}
                      paddingAngle={8}
                      dataKey="value"
                    >
                      {roleData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip 
                      contentStyle={{ backgroundColor: '#0f172a', border: '1px solid #1e293b', borderRadius: '12px', fontSize: '12px' }}
                      itemStyle={{ color: '#f8fafc', fontWeight: 'bold' }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              )}
            </div>
            <div className="mt-4 grid grid-cols-2 gap-4">
               {roleData.map((role, i) => (
                 <div key={role.name} className="flex items-center gap-2">
                    <div className="h-2 w-2 rounded-full" style={{ backgroundColor: COLORS[i % COLORS.length] }} />
                    <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest">{role.name}: {role.value}</span>
                 </div>
               ))}
            </div>
          </motion.div>

          {/* Task Status */}
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
            className="lg:col-span-2 bg-slate-900 border border-slate-800 rounded-3xl p-8 backdrop-blur-xl"
          >
            <h3 className="text-lg font-black text-white mb-6 flex items-center gap-2">
               <Target size={20} className="text-emerald-500" />
               Operational Velocity
            </h3>
            <div className="h-[250px] w-full">
              {isMounted && (
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={taskData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" vertical={false} />
                    <XAxis dataKey="name" stroke="#64748b" fontSize={10} axisLine={false} tickLine={false} />
                    <YAxis stroke="#64748b" fontSize={10} axisLine={false} tickLine={false} />
                    <Tooltip 
                      cursor={{ fill: '#1e293b' }}
                      contentStyle={{ backgroundColor: '#0f172a', border: '1px solid #1e293b', borderRadius: '12px', fontSize: '12px' }}
                      itemStyle={{ color: '#f8fafc', fontWeight: 'bold' }}
                    />
                    <Bar dataKey="value" fill="#3b82f6" radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </div>
          </motion.div>
        </div>

        {/* Bottom Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
           {/* Top Performers */}
           <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7 }}
            className="bg-slate-900 border border-slate-800 rounded-3xl p-8 backdrop-blur-xl"
          >
            <h3 className="text-lg font-black text-white mb-6 flex items-center gap-2">
               <Zap size={20} className="text-amber-500" />
               High Impact Members
            </h3>
            <div className="space-y-4">
               {data.topPerformers?.length > 0 ? data.topPerformers.map((performer: any, i: number) => (
                 <div key={performer.id} className="flex items-center justify-between p-4 bg-slate-950/50 border border-slate-800 rounded-2xl group hover:border-blue-500/30 transition-all cursor-default">
                    <div className="flex items-center gap-4">
                       <div className="h-5 w-5 bg-slate-800 rounded-full flex items-center justify-center text-[10px] font-black text-slate-500 border border-slate-700">
                          {i + 1}
                       </div>
                       <div className="h-10 w-10 bg-slate-800 rounded-xl border border-slate-700 font-bold overflow-hidden flex items-center justify-center text-slate-500">
                          {performer.profileImageUrl ? <img src={performer.profileImageUrl} alt="" className="h-full w-full object-cover" /> : (performer.name ? performer.name[0] : '?')}
                       </div>
                       <div>
                          <p className="text-sm font-bold text-white group-hover:text-blue-400 transition-colors">{performer.name || 'Unknown Agent'}</p>
                          <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest">{performer.role}</p>
                       </div>
                    </div>
                    <div className="text-right">
                       <p className="text-sm font-black text-orange-500">{performer.activityPoints || 0} APT</p>
                       <p className="text-[10px] font-bold text-slate-600 uppercase tracking-tighter">Verified Achievement</p>
                    </div>
                 </div>
               )) : (
                 <p className="text-sm italic text-slate-500 p-4 border border-slate-800 border-dashed rounded-2xl text-center">No commendations recorded</p>
               )}
            </div>
          </motion.div>

           <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.8 }}
            className="bg-slate-900 border border-slate-800 rounded-3xl p-8 backdrop-blur-xl relative overflow-hidden"
          >
            <div className="absolute top-0 right-0 p-8 opacity-10 pointer-events-none">
               <Activity size={120} className="text-blue-500" />
            </div>
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-black text-white flex items-center gap-2">
                 <History size={20} className="text-blue-500" />
                 Pulse Activity Stream
              </h3>
              <Link 
                href="/audit"
                className="text-[10px] font-black text-blue-500 uppercase tracking-widest hover:text-blue-400 transition-colors flex items-center gap-1 group/link"
              >
                View Full Audit Trail
                <Rocket size={10} className="group-hover/link:translate-x-1 transition-transform" />
              </Link>
            </div>
            <div className="space-y-6 relative z-10">
               {data.recentActivities?.length > 0 ? data.recentActivities.map((activity: any) => (
                 <div key={activity.id} className="flex gap-4 group">
                    <div className="flex flex-col items-center">
                       <div className="h-10 w-10 bg-slate-950 border border-slate-800 rounded-xl flex items-center justify-center text-blue-500 shadow-xl group-hover:border-blue-500/30 transition-all">
                          <Zap size={16} className={cn(
                             activity.type.includes('COMPLETED') ? "text-emerald-500" : 
                             activity.type.includes('ADDED') ? "text-blue-500" : "text-amber-500"
                          )} />
                       </div>
                       <div className="w-px flex-1 bg-slate-800/50 my-2" />
                    </div>
                    <div className="pb-4">
                       <p className="text-base font-bold text-slate-200 leading-snug">
                          <span className="text-blue-400 font-black tracking-tight">@{activity.user?.name || 'SYSTEM'}</span> {activity.content}
                       </p>
                       <div className="flex items-center gap-3 mt-1.5">
                          <span className="text-[10px] font-black text-slate-600 uppercase tracking-[0.2em]">
                             {new Date(activity.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </span>
                          <div className="h-1 w-1 rounded-full bg-slate-700" />
                          <span className="px-2 py-0.5 rounded bg-blue-500/10 text-[8px] font-black text-blue-500/80 border border-blue-500/10 uppercase tracking-widest leading-none">
                             {activity.type.replace('_', ' ')}
                          </span>
                       </div>
                    </div>
                 </div>
               )) : (
                 <div className="text-center py-20 border-2 border-dashed border-slate-800 rounded-3xl">
                    <Activity size={40} className="mx-auto mb-4 opacity-10" />
                    <p className="text-sm italic text-slate-600 font-bold uppercase tracking-widest">Awaiting Pulse Signal...</p>
                 </div>
               )}
            </div>
          </motion.div>
        </div>
      </main>
    </div>
  );
}

function StatCard({ title, value, icon, trend, color, delay }: { title: string, value: any, icon: React.ReactNode, trend: string, color: string, delay: number }) {
  const colors: any = {
    blue: "bg-blue-500/5 border-blue-500/10 text-blue-500",
    amber: "bg-amber-500/5 border-amber-500/10 text-amber-500",
    emerald: "bg-emerald-500/5 border-emerald-500/10 text-emerald-500",
    purple: "bg-purple-500/5 border-purple-500/10 text-purple-500",
  };

  return (
    <motion.div 
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ delay }}
      className="bg-slate-900 border border-slate-800 p-6 rounded-3xl relative overflow-hidden group hover:border-slate-700 transition-all cursor-default"
    >
      <div className={cn("inline-flex p-3 rounded-2xl mb-4 shadow-sm", colors[color])}>
        {icon}
      </div>
      <div>
        <p className="text-4xl font-black text-white mb-1">{value}</p>
        <p className="text-[10px] font-black text-slate-500 uppercase tracking-wider mb-2">{title}</p>
        <div className="flex items-center gap-1.5 pt-3 border-t border-slate-800/50">
           <TrendingUp size={10} className={cn(colors[color].replace('bg-', 'text-'))} />
           <span className="text-[10px] font-bold text-slate-400">{trend}</span>
        </div>
      </div>
    </motion.div>
  );
}
