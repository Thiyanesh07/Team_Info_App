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
    <div className="flex flex-col lg:flex-row min-h-screen bg-[#131313] text-[#FFFFFF]">
      <Sidebar />
      
      <main className="flex-1 p-6 md:p-10 overflow-y-auto mt-16 lg:mt-0 custom-scrollbar no-scrollbar">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-[#4B4A48] pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl md:text-5xl font-black tracking-tighter text-[#FFFFFF] uppercase italic">Squad Reports</h2>
            <p className="text-[#A4A4A4] mt-1 text-[10px] md:text-xs font-black uppercase tracking-[0.2em] opacity-60">Global monitoring of daily progress units.</p>
          </motion.div>
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-4 w-full md:w-auto">
             <div className="relative flex-1 md:flex-none h-11">
               <select 
                 className="w-full h-full bg-[#131313] border border-[#4B4A48] rounded px-5 text-[10px] font-black uppercase tracking-widest text-[#777674] outline-none focus:border-[#EFD395] transition-all appearance-none cursor-pointer italic"
                 value={filterUser}
                 onChange={(e) => setFilterUser(e.target.value)}
               >
                  <option value="">ALL AGENTS</option>
                  {users.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}
               </select>
               <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-[#4B4A48]">
                 <ChevronRight size={14} className="rotate-90" />
               </div>
             </div>
             <button 
              onClick={handleExport}
              className="px-8 py-2.5 bg-[#EFD395] text-[#131313] rounded flex items-center justify-center gap-2 hover:bg-white transition-all font-black text-[10px] uppercase tracking-widest h-11 shadow-lg active:scale-95"
            >
              <Download size={14} />
              Export
            </button>
          </div>
        </header>

        <div className="space-y-6">
          {filteredReports.map((report, i) => (
            <motion.div 
              key={report.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="group border border-[#4B4A48] rounded p-6 md:p-10 bg-[#262625] hover:border-[#EFD395]/30 transition-all flex flex-col sm:flex-row items-start gap-6 md:gap-12 relative overflow-hidden shadow-xl"
            >
               <div className="flex-shrink-0 relative z-10">
                  <div className="h-14 w-14 bg-[#131313] border border-[#4B4A48] rounded flex items-center justify-center font-black text-lg text-[#EFD395] shadow-inner italic group-hover:border-[#EFD395]/40 transition-colors">
                     {report.user?.name?.[0] || 'A'}
                  </div>
               </div>
               
               <div className="flex-1 min-w-0 w-full relative z-10">
                  <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 gap-4">
                     <div className="flex flex-wrap items-center gap-3 md:gap-6">
                        <span className="text-[11px] font-black text-[#FFFFFF] uppercase tracking-tighter italic whitespace-nowrap bg-[#131313]/50 px-3 py-1 rounded border border-[#4B4A48]/30">@{report.user?.name}</span>
                        <div className="px-3 py-1 border border-[#4B4A48] rounded text-[8px] font-black text-[#EFD395] uppercase tracking-[0.2em] whitespace-nowrap bg-[#131313] shadow-inner italic">{report.type}</div>
                     </div>
                     <div className="flex items-center gap-2 text-[#777674] ml-auto sm:ml-0 group-hover:text-[#A4A4A4] transition-colors">
                        <Clock size={14} className="text-[#EFD395]" />
                        <span className="text-[9px] font-black uppercase tracking-[0.2em] italic">{new Date(report.createdAt).toLocaleDateString()}</span>
                     </div>
                  </div>
                  <p className="text-[12px] md:text-sm text-[#A4A4A4] leading-relaxed italic opacity-80 group-hover:opacity-100 transition-opacity whitespace-pre-wrap break-words border-l-2 border-[#4B4A48]/30 pl-6 py-1 group-hover:border-[#EFD395]/40">
                     {report.description}
                  </p>
                  
                  {report.hoursSpent && (
                     <div className="mt-8 flex items-center justify-between border-t border-[#4B4A48]/20 pt-4">
                        <div className="flex items-center gap-3">
                           <Zap size={12} className="text-[#EFD395]" />
                           <span className="text-[8px] font-black text-[#777674] uppercase tracking-[0.3em] italic">Temporal Impact: <span className="text-[#FFFFFF]">{report.hoursSpent} Hours</span></span>
                        </div>
                        <Shield size={12} className="text-[#4B4A48] group-hover:text-[#EFD395]/40 transition-colors" />
                     </div>
                  )}
               </div>

               <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-bl from-[#EFD395]/5 to-transparent pointer-events-none opacity-0 group-hover:opacity-100 transition-opacity" />
            </motion.div>
          ))}

          {filteredReports.length === 0 && !loading && (
            <div className="p-32 text-center border border-dashed border-[#4B4A48] rounded group">
               <p className="text-[10px] font-black text-[#777674] uppercase tracking-[0.5em] italic group-hover:text-[#EFD395] transition-colors">No Reports Transmitted</p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
