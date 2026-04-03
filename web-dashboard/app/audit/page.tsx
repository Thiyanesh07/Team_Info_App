'use client';
import { useState, useEffect } from 'react';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { ShieldAlert, Terminal, Clock, Filter, AlertCircle, Info, CheckCircle, Database, Activity, ShieldCheck, Zap, X } from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';

const EVENT_TYPES = [
  { id: 'all', label: 'ALL EVENTS', icon: Database },
  { id: 'AUTH', label: 'AUTH', icon: ShieldAlert },
  { id: 'SECURITY', label: 'SECURITY', icon: AlertCircle },
  { id: 'DATA_CHANGE', label: 'DATA', icon: Info },
];

export default function AuditPage() {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeFilter, setActiveFilter] = useState('all');

  useEffect(() => {
    fetchLogs();
  }, []);

  const fetchLogs = async () => {
    try {
      const res = await api.get('/system-activities/unified');
      if (res.data.success) {
        setLogs(res.data.data);
      }
    } catch (err) {
      console.error('Fetch logs error:', err);
    } finally {
      setLoading(false);
    }
  };

  const filteredLogs = logs.filter(log => 
    activeFilter === 'all' || (log.type && log.type.includes(activeFilter))
  );

  return (
    <div className="flex flex-col lg:flex-row min-h-screen bg-[#131313] text-[#FFFFFF]">
      <Sidebar />
      
      <main className="flex-1 p-6 md:p-10 overflow-y-auto mt-16 lg:mt-0 custom-scrollbar no-scrollbar">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-[#4B4A48] pb-10 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-4xl md:text-6xl font-black tracking-tighter text-[#FFFFFF] uppercase italic">Security Audit</h2>
            <p className="text-[#A4A4A4] mt-1 text-[10px] md:text-xs font-black uppercase tracking-[0.2em] opacity-60">Real-time oversight of administrative actions.</p>
          </motion.div>
          <div className="flex gap-2 border border-[#4B4A48] p-1.5 rounded bg-[#262625] overflow-x-auto no-scrollbar w-full md:w-auto shadow-inner">
             {EVENT_TYPES.map(filter => (
               <button 
                 key={filter.id}
                 onClick={() => setActiveFilter(filter.id)}
                 className={cn(
                   "flex flex-1 md:flex-none items-center justify-center gap-3 px-6 py-2.5 rounded text-[9px] font-black tracking-[0.2em] uppercase transition-all whitespace-nowrap italic",
                   activeFilter === filter.id 
                    ? "bg-[#EFD395] text-[#131313] shadow-lg" 
                    : "text-[#777674] hover:text-[#A4A4A4] hover:bg-[#131313]"
                 )}
               >
                 <filter.icon size={14} />
                 {filter.label}
               </button>
             ))}
          </div>
        </header>

        <div className="border border-[#4B4A48] rounded bg-[#262625] shadow-2xl relative overflow-hidden group">
           <div className="absolute top-0 right-0 w-64 h-64 bg-[#EFD395]/5 blur-[100px] pointer-events-none"></div>
           <div className="p-8 border-b border-[#4B4A48] flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6 bg-[#131313]/30">
              <h3 className="text-[11px] font-black flex items-center gap-4 uppercase tracking-[0.4em] text-[#A4A4A4] italic">
                <Terminal size={18} className="text-[#EFD395]" /> Historical Event Timeline
              </h3>
              <div className="flex items-center gap-3 bg-[#131313] px-4 py-2 rounded border border-[#4B4A48] shadow-inner">
                 <div className="h-2 w-2 rounded-full bg-[#EFD395] animate-pulse shadow-[0_0_8px_rgba(239,211,149,0.5)]" />
                 <span className="text-[9px] font-black text-[#EFD395] uppercase tracking-[0.3em] italic">Live Monitoring Active</span>
              </div>
           </div>

           <div className="max-h-[75vh] overflow-y-auto custom-scrollbar no-scrollbar">
              {loading ? (
                <div className="p-40 text-center uppercase font-black text-[10px] tracking-[0.6em] text-[#4B4A48] animate-pulse italic">
                   Synchronizing Logs...
                </div>
              ) : (
                <div className="divide-y divide-[#4B4A48]/30">
                  {filteredLogs.map((log: any) => (
                    <motion.div 
                      key={log.id} 
                      initial={{ opacity: 0 }} 
                      animate={{ opacity: 1 }}
                      className="p-8 md:p-10 hover:bg-[#131313]/50 transition-all flex gap-8 md:gap-10 items-start group relative"
                    >
                       <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-bl from-[#EFD395]/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none" />
                       <div className="flex-shrink-0 mt-1">
                          <div className={cn(
                            "h-12 w-12 rounded bg-[#131313] border flex items-center justify-center transition-all shadow-inner",
                            log.type?.includes('AUTH') ? "border-[#EFD395]/40 text-[#EFD395] group-hover:border-[#EFD395]" :
                            log.type?.includes('SECURITY') ? "border-red-500/40 text-red-500" :
                            "border-[#4B4A48] text-[#777674] group-hover:border-[#A4A4A4]"
                          )}>
                             {log.type?.includes('AUTH') ? <ShieldCheck size={20} /> : 
                              log.type?.includes('DATA') ? <Database size={20} /> :
                              <Zap size={20} />}
                          </div>
                       </div>
                       <div className="flex-1 min-w-0 z-10">
                          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-4 gap-3">
                             <h4 className="font-black text-white uppercase italic tracking-tight text-base truncate w-full sm:w-auto">{log.title}</h4>
                             <span className="text-[10px] text-[#EFD395] font-black tracking-[0.2em] uppercase whitespace-nowrap bg-[#131313] px-4 py-1.5 rounded shadow-inner italic border border-[#4B4A48]/30">
                               {log.timestamp ? format(new Date(log.timestamp), 'HH:mm:ss | dd MMM') : '---'}
                             </span>
                          </div>
                          <p className="text-sm text-[#A4A4A4] leading-relaxed italic border-l-2 border-[#4B4A48]/30 pl-6 group-hover:border-[#EFD395]/40 transition-colors">{log.content}</p>
                          <div className="mt-8 flex flex-wrap items-center gap-8">
                            <div className="flex items-center gap-4">
                               <div className="h-8 w-8 bg-[#131313] border border-[#4B4A48] rounded flex items-center justify-center text-[10px] font-black text-[#EFD395] italic shadow-inner group-hover:border-[#EFD395] transition-colors">
                                  {log.user?.name?.[0] || 'S'}
                               </div>
                               <span className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] italic group-hover:text-white transition-colors">@{log.user?.name || 'System Agent'}</span>
                            </div>
                            <span className="px-4 py-1.5 rounded bg-[#131313] border border-[#4B4A48] text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.4em] italic group-hover:text-[#EFD395] transition-colors shadow-inner">{log.type?.replace('_', ' ')}</span>
                          </div>
                       </div>
                    </motion.div>
                  ))}
                  
                  {filteredLogs.length === 0 && (
                    <div className="p-40 text-center border border-dashed border-[#4B4A48] m-10 rounded group">
                       <p className="font-black uppercase tracking-[0.6em] text-[11px] text-[#777674] italic group-hover:text-[#EFD395] transition-colors">No Administrative Records Found</p>
                    </div>
                  )}
                </div>
              )}
           </div>
        </div>
      </main>
    </div>
  );
}
