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
    <div className="flex flex-col lg:flex-row min-h-screen bg-[#121212] text-[#E0E0E0]">
      <Sidebar />
      
      <main className="flex-1 p-6 md:p-10 overflow-y-auto mt-16 lg:mt-0">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-[#444444] pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl md:text-4xl font-black tracking-tighter text-[#E0E0E0] uppercase italic">Security Audit</h2>
            <p className="text-[#B0B0B0] mt-1 text-[10px] md:text-xs font-bold uppercase tracking-[0.2em] opacity-60">Real-time oversight of administrative actions.</p>
          </motion.div>
          <div className="flex gap-1 border border-[#444444] p-1 rounded-md overflow-x-auto custom-scrollbar no-scrollbar w-full md:w-auto">
             {EVENT_TYPES.map(filter => (
               <button 
                 key={filter.id}
                 onClick={() => setActiveFilter(filter.id)}
                 className={cn(
                   "flex flex-1 md:flex-none items-center justify-center gap-2 px-4 py-2 rounded text-[8px] font-black tracking-widest uppercase transition-all whitespace-nowrap",
                   activeFilter === filter.id 
                    ? "bg-[#444444] text-[#E0E0E0]" 
                    : "text-[#888888] hover:text-[#B0B0B0]"
                 )}
               >
                 <filter.icon size={12} />
                 {filter.label}
               </button>
             ))}
          </div>
        </header>

        <div className="border border-[#444444] rounded-lg overflow-hidden bg-transparent">
           <div className="p-4 md:p-6 border-b border-[#444444] flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <h3 className="text-[10px] md:text-xs font-black flex items-center gap-3 uppercase tracking-[0.3em] text-[#888888]">
                <Terminal size={14} /> Historical Event Timeline
              </h3>
              <div className="flex items-center gap-2">
                 <div className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
                 <span className="text-[8px] font-black text-[#444444] uppercase tracking-widest">Live Monitoring Active</span>
              </div>
           </div>

           <div className="max-h-[75vh] overflow-y-auto custom-scrollbar">
              {loading ? (
                <div className="p-32 text-center uppercase font-black text-[10px] tracking-[0.5em] text-[#444444] animate-pulse">
                   Synchronizing Logs...
                </div>
              ) : (
                <div className="divide-y divide-[#444444]">
                  {filteredLogs.map((log: any) => (
                    <motion.div 
                      key={log.id} 
                      initial={{ opacity: 0 }} 
                      animate={{ opacity: 1 }}
                      className="p-4 md:p-6 hover:bg-[#444444]/5 transition-colors flex gap-4 md:gap-6 items-start group"
                    >
                       <div className="flex-shrink-0 mt-1">
                          <div className={cn(
                            "h-8 w-8 rounded border flex items-center justify-center transition-all",
                            log.type?.includes('AUTH') ? "border-blue-500/20 text-blue-500" :
                            log.type?.includes('SECURITY') ? "border-red-500/20 text-red-500" :
                            "border-[#444444] text-[#888888]"
                          )}>
                             {log.type?.includes('AUTH') ? <ShieldCheck size={14} /> : 
                              log.type?.includes('DATA') ? <Database size={14} /> :
                              <Zap size={14} />}
                          </div>
                       </div>
                       <div className="flex-1 min-w-0">
                          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-1 gap-1">
                             <h4 className="font-black text-[#E0E0E0] uppercase tracking-tight text-xs truncate w-full sm:w-auto">{log.title}</h4>
                             <span className="text-[8px] md:text-[9px] text-[#444444] font-black tracking-widest uppercase whitespace-nowrap">
                               {log.timestamp ? format(new Date(log.timestamp), 'HH:mm:ss | dd MMM') : '---'}
                             </span>
                          </div>
                          <p className="text-[11px] md:text-xs text-[#B0B0B0] opacity-60 leading-relaxed italic">{log.content}</p>
                          <div className="mt-4 flex flex-wrap items-center gap-4">
                            <div className="flex items-center gap-2">
                               <div className="h-5 w-5 bg-[#444444]/20 border border-[#444444] rounded-sm flex items-center justify-center text-[8px] font-bold">
                                  {log.user?.name?.[0] || 'S'}
                               </div>
                               <span className="text-[8px] md:text-[9px] font-black text-[#444444] uppercase tracking-widest">@{log.user?.name || 'System'}</span>
                            </div>
                            <span className="px-2 py-0.5 rounded-sm bg-transparent border border-[#444444] text-[8px] font-black text-[#888888] uppercase tracking-widest">{log.type?.replace('_', ' ')}</span>
                          </div>
                       </div>
                    </motion.div>
                  ))}
                  
                  {filteredLogs.length === 0 && (
                    <div className="p-32 text-center uppercase font-black text-[10px] tracking-[0.5em] text-[#444444]">
                       No Records Found
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
