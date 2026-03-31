'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { CheckSquare, Clock, User, AlertCircle, ExternalLink, Filter, Search, ChevronRight } from 'lucide-react';
import { cn } from '@/lib/utils';
import { motion } from 'framer-motion';

export default function TasksPage() {
  const [tasks, setTasks] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('ALL');

  useEffect(() => {
    fetchTasks();
  }, []);

  const fetchTasks = async () => {
    try {
      const res = await api.get('/tasks/all');
      if (res.data.success) {
        setTasks(res.data.data);
      }
    } catch (err) {
      console.error('Fetch tasks error:', err);
    } finally {
      setLoading(false);
    }
  };

  const filteredTasks = tasks.filter(t => filter === 'ALL' || t.status === filter);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'COMPLETED': return 'text-emerald-500 bg-emerald-500/10 border-emerald-500/20';
      case 'IN_PROGRESS': return 'text-blue-500 bg-blue-500/10 border-blue-500/20';
      case 'PENDING': return 'text-amber-500 bg-amber-500/10 border-amber-500/20';
      default: return 'text-slate-400 bg-slate-400/10 border-slate-400/20';
    }
  };

  return (
    <div className="flex min-h-screen bg-slate-950 text-slate-50">
      <Sidebar />
      
      <main className="flex-1 p-8 overflow-y-auto">
        <header className="mb-10 flex justify-between items-center">
          <div>
            <h2 className="text-3xl font-black tracking-tight text-white uppercase">Task Command Center</h2>
            <p className="text-slate-400 mt-1 font-medium italic">Global tracking of all active assignments and operational milestones.</p>
          </div>
          <div className="flex gap-2">
            {['ALL', 'PENDING', 'IN_PROGRESS', 'COMPLETED'].map((f) => (
              <button 
                key={f}
                onClick={() => setFilter(f)}
                className={cn(
                  "px-4 py-2 rounded-xl text-[10px] font-black tracking-widest uppercase border transition-all",
                  filter === f ? "bg-blue-600 border-blue-500 text-white shadow-lg shadow-blue-600/20" : "bg-slate-900 border-slate-800 text-slate-500 hover:text-slate-300"
                )}
              >
                {f}
              </button>
            ))}
          </div>
        </header>

        <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
          {filteredTasks.map((task, i) => (
            <motion.div 
              key={task.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.05 }}
              className="bg-slate-900 border border-slate-800 rounded-3xl p-6 hover:border-slate-700 transition-all group relative overflow-hidden"
            >
              <div className="absolute top-0 right-0 p-4 opacity-0 group-hover:opacity-100 transition-opacity">
                 <button className="p-2 bg-slate-950/50 border border-slate-800 rounded-lg hover:text-blue-400 transition-colors">
                    <ExternalLink size={16} />
                 </button>
              </div>

              <div className="flex gap-6">
                {/* Status Column */}
                <div className="flex flex-col items-center gap-2">
                  <div className={cn("inline-flex p-3 rounded-2xl border", getStatusColor(task.status))}>
                    <CheckSquare size={20} strokeWidth={2.5} />
                  </div>
                  <div className="w-[2px] h-full bg-slate-800/50 rounded-full" />
                </div>

                <div className="flex-1">
                  <div className="flex justify-between items-start mb-2">
                    <h3 className="text-lg font-black text-white group-hover:text-blue-400 transition-colors">{task.title}</h3>
                    <span className={cn("px-2 py-0.5 rounded-md text-[8px] font-black uppercase tracking-wider border", getStatusColor(task.status))}>
                      {task.status}
                    </span>
                  </div>
                  
                  <p className="text-sm text-slate-500 line-clamp-2 mb-6 leading-relaxed">
                    {task.description || 'No detailed instructions provided for this assignment.'}
                  </p>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="flex items-center gap-3 bg-slate-950/50 p-3 rounded-2xl border border-slate-800/50">
                       <div className="h-8 w-8 bg-blue-500/10 rounded-lg flex items-center justify-center text-blue-500 border border-blue-500/20">
                          <User size={14} />
                       </div>
                       <div>
                          <p className="text-[8px] font-black text-slate-500 uppercase">Assigned To</p>
                          <p className="text-xs font-bold text-slate-200">{task.assignee?.name || 'Unassigned'}</p>
                       </div>
                    </div>

                    <div className="flex items-center gap-3 bg-slate-950/50 p-3 rounded-2xl border border-slate-800/50">
                       <div className="h-8 w-8 bg-orange-500/10 rounded-lg flex items-center justify-center text-orange-500 border border-orange-500/20">
                          <Clock size={14} />
                       </div>
                       <div>
                          <p className="text-[8px] font-black text-slate-500 uppercase">Deadline</p>
                          <p className="text-xs font-bold text-slate-200">
                             {task.deadline ? new Date(task.deadline).toLocaleDateString() : 'NO LIMIT'}
                          </p>
                       </div>
                    </div>
                  </div>

                  <div className="mt-6 flex items-center justify-between">
                     <span className="text-[10px] font-black text-slate-600 uppercase tracking-widest flex items-center gap-1.5">
                        <AlertCircle size={12} className="text-slate-700" /> System Unit: #{task.id.slice(-6)}
                     </span>
                     <button className="text-[10px] font-black text-blue-500 hover:text-blue-400 flex items-center gap-1 transition-colors uppercase tracking-widest">
                        View Progress <ChevronRight size={12} strokeWidth={3} />
                     </button>
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {filteredTasks.length === 0 && !loading && (
          <div className="p-32 text-center text-slate-500 border-2 border-dashed border-slate-800 rounded-[3rem]">
            <CheckSquare size={48} className="mx-auto mb-4 opacity-10" />
            <p className="font-bold text-lg uppercase tracking-widest">Zero Operations Identified</p>
            <p className="text-sm mt-1">Assignments tracking will initialize once operations begin.</p>
          </div>
        )}
      </main>
    </div>
  );
}
