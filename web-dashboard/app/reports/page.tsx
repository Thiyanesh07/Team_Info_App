'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api, { downloadExcel } from '@/lib/api';
import { FileText, Clock, User, Download, Search, Filter, ChevronRight, X, Calendar, Activity, Zap, Shield } from 'lucide-react';
import { toast } from 'sonner';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';

export default function ReportsPage() {
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [users, setUsers] = useState<any[]>([]);
  const [filterUser, setFilterUser] = useState('');
  const [filterType, setFilterType] = useState('ALL');

  useEffect(() => {
    fetchReports();
    fetchUsers();
  }, []);

  const fetchReports = async () => {
    try {
      const res = await api.get('/daily-activities/all');
      if (res.data.success) {
        setReports(res.data.data);
      }
    } catch (err) {
      console.error('Fetch reports error:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchUsers = async () => {
    try {
      const res = await api.get('/users');
      if (res.data.success) {
        setUsers(res.data.data);
      }
    } catch (err) {
      console.error('Fetch users error:', err);
    }
  };

  const handleExport = async () => {
    try {
      toast.info('Generating... ');
      await downloadExcel('/export/activities', `Reports_${Date.now()}.xlsx`, { scope: 'TEAM' });
      toast.success('Downloaded');
    } catch (err: any) {
      toast.error('Export Failed');
    }
  };

  const filteredReports = reports.filter(r => {
    const userMatch = filterUser === '' || r.userId === filterUser;
    const typeMatch = filterType === 'ALL' || r.type === filterType;
    return userMatch && typeMatch;
  });

  return (
    <div className="flex flex-col lg:flex-row min-h-screen bg-slate-950 text-slate-50">
      <Sidebar />
      
      <main className="flex-1 p-6 md:p-10 overflow-y-auto mt-16 lg:mt-0">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-slate-800 pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl md:text-4xl font-black tracking-tighter text-white uppercase italic">Squad Reports</h2>
            <p className="text-slate-400 mt-1 text-[10px] md:text-xs font-black uppercase tracking-[0.2em] opacity-60">Global monitoring of daily progress units.</p>
          </motion.div>
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 w-full md:w-auto">
             <select 
               className="bg-slate-900 border border-slate-800 rounded-xl px-4 py-2 text-[10px] font-black uppercase text-slate-500 outline-none h-11 focus:border-blue-500/50 transition-all appearance-none pr-8"
               value={filterUser}
               onChange={(e) => setFilterUser(e.target.value)}
             >
                <option value="">ALL AGENTS</option>
                {users.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}
             </select>
             <button 
              onClick={handleExport}
              className="px-6 py-2.5 bg-blue-600 text-white rounded-xl flex items-center justify-center gap-2 hover:bg-blue-500 transition-all font-black text-[10px] uppercase tracking-widest h-11 shadow-lg shadow-blue-600/20"
            >
              <Download size={14} />
              Export
            </button>
          </div>
        </header>

        <div className="space-y-4">
          {filteredReports.map((report, i) => (
            <motion.div 
              key={report.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="group border border-slate-800 rounded-[2rem] p-6 md:p-8 bg-slate-900/40 hover:bg-slate-900/60 hover:border-slate-700 backdrop-blur-xl transition-all flex flex-col sm:flex-row items-start gap-4 md:gap-10"
            >
               <div className="flex-shrink-0">
                  <div className="h-12 w-12 bg-slate-800 border border-slate-700 rounded-2xl flex items-center justify-center font-black text-xs text-slate-400 shadow-inner">
                     {report.user?.name?.[0] || 'A'}
                  </div>
               </div>
               
               <div className="flex-1 min-w-0 w-full">
                  <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-4 gap-2">
                     <div className="flex flex-wrap items-center gap-2 md:gap-4">
                        <span className="text-[10px] font-black text-white uppercase tracking-tighter italic whitespace-nowrap">@{report.user?.name}</span>
                        <div className="px-2 py-0.5 border border-slate-800 rounded-lg text-[8px] font-black text-slate-500 uppercase tracking-widest whitespace-nowrap bg-slate-950/50">{report.type}</div>
                     </div>
                     <div className="flex items-center gap-2 text-slate-600 ml-auto sm:ml-0">
                        <Clock size={12} />
                        <span className="text-[9px] font-black uppercase tracking-widest">{new Date(report.createdAt).toLocaleDateString()}</span>
                     </div>
                  </div>
                  <p className="text-[11px] md:text-sm text-slate-400 leading-relaxed italic opacity-80 group-hover:opacity-100 transition-opacity whitespace-pre-wrap break-words">
                     {report.description}
                  </p>
                  
                  {report.hoursSpent && (
                     <div className="mt-4 flex items-center gap-2">
                        <span className="text-[8px] font-black text-slate-700 uppercase tracking-widest">Temporal Impact: {report.hoursSpent} Hours</span>
                     </div>
                  )}
               </div>
            </motion.div>
          ))}

          {filteredReports.length === 0 && !loading && (
            <div className="p-32 text-center border border-dashed border-slate-800 rounded-[3rem]">
               <p className="text-[10px] font-black text-slate-700 uppercase tracking-[0.5em]">No Reports Transmitted</p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
