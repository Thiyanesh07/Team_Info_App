'use client';
import { useState, useEffect } from 'react';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { ShieldAlert, Terminal, Clock, Filter, AlertCircle, Info, CheckCircle, Database, Activity } from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';

const EVENT_TYPES = [
  { id: 'all', label: 'All Events', icon: Database, color: 'text-slate-400' },
  { id: 'AUTH', label: 'Authentication', icon: ShieldAlert, color: 'text-blue-400' },
  { id: 'SECURITY', label: 'Security', icon: AlertCircle, color: 'text-red-400' },
  { id: 'DATA_CHANGE', label: 'Data Changes', icon: Info, color: 'text-amber-400' },
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
    activeFilter === 'all' || log.type.includes(activeFilter)
  );

  return (
    <div className="flex min-h-screen bg-slate-950 text-slate-50">
      <Sidebar />
      
      <main className="flex-1 p-8">
        <header className="flex justify-between items-center mb-10">
          <div>
            <h2 className="text-3xl font-bold tracking-tight">System Audit & Lifecycle</h2>
            <p className="text-slate-400 mt-1">Real-time oversight of administrative actions and security events</p>
          </div>
          <div className="flex bg-slate-900 border border-slate-800 rounded-xl p-1 p-1 gap-1">
             {EVENT_TYPES.map(filter => (
               <button 
                 key={filter.id}
                 onClick={() => setActiveFilter(filter.id)}
                 className={cn(
                   "flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all",
                   activeFilter === filter.id 
                    ? "bg-blue-600 text-white shadow-lg shadow-blue-600/20" 
                    : "text-slate-500 hover:text-slate-300 hover:bg-slate-800"
                 )}
               >
                 <filter.icon size={14} />
                 {filter.label}
               </button>
             ))}
          </div>
        </header>

        <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-2xl relative">
          <div className="absolute top-0 right-0 p-4">
             <Terminal size={18} className="text-slate-800" />
          </div>
          
          <div className="p-6 border-b border-slate-800 bg-slate-950/20">
             <h3 className="text-lg font-bold flex items-center gap-3">
               <Clock size={18} className="text-blue-500" />
               Historical Event Timeline
             </h3>
          </div>

          <div className="p-0 max-h-[70vh] overflow-y-auto">
             {loading ? (
               <div className="p-20 text-center">
                 <div className="animate-spin rounded-full h-10 w-12 border-t-2 border-b-2 border-blue-500 mx-auto"></div>
                 <p className="text-slate-500 mt-4 italic font-bold text-xs uppercase tracking-widest">Parsing audit trails...</p>
               </div>
             ) : (
               <div className="divide-y divide-slate-800">
                 {filteredLogs.map((log: any) => (
                   <div key={log.id} className="p-5 hover:bg-slate-800/30 transition-colors flex gap-6 items-start group">
                      <div className="flex-shrink-0 mt-1">
                         <div className={cn(
                           "h-10 w-10 rounded-xl flex items-center justify-center border",
                           log.type.includes('AUTH') ? "bg-blue-600/10 border-blue-600/20 text-blue-500" :
                           log.type.includes('ERROR') ? "bg-red-600/10 border-red-600/20 text-red-500" :
                           "bg-amber-600/10 border-amber-600/20 text-amber-500"
                         )}>
                           {log.type.includes('AUTH') ? <ShieldAlert size={20} /> : 
                            log.type.includes('DATA') ? <Database size={20} /> :
                            <Activity size={20} />}
                         </div>
                      </div>
                      <div className="flex-1">
                         <div className="flex justify-between text-sm mb-1">
                            <h4 className="font-extrabold text-slate-100 uppercase tracking-tight text-xs">{log.title}</h4>
                            <span className="text-[10px] text-slate-600 font-bold tracking-widest uppercase">{format(new Date(log.createdAt), 'MMM dd | HH:mm:ss')}</span>
                         </div>
                         <p className="text-sm text-slate-400 group-hover:text-slate-300 transition-colors">{log.content}</p>
                         <div className="mt-3 flex items-center gap-2">
                           <span className="px-2 py-0.5 rounded-md bg-slate-800 text-[10px] font-bold text-slate-500 border border-slate-700 uppercase">Actor: {log.user?.name || 'System'}</span>
                           <span className="px-2 py-0.5 rounded-md bg-slate-800 text-[10px] font-bold text-slate-500 border border-slate-700 uppercase">Type: {log.type.replace('_', ' ')}</span>
                         </div>
                      </div>
                   </div>
                 ))}
                 
                 {filteredLogs.length === 0 && (
                   <div className="p-20 text-center text-slate-600 italic">
                      No logs found matching the selected filter
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
