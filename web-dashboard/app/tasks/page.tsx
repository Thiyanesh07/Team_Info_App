'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api, { downloadExcel } from '@/lib/api';
import { CheckSquare, Clock, User, AlertCircle, ExternalLink, Filter, Search, ChevronRight, Plus, X, Trash2, Edit3, FileSpreadsheet, RotateCcw, Calendar, Shield } from 'lucide-react';
import { toast } from 'sonner';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';

export default function TasksPage() {
  const [tasks, setTasks] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('ALL');
  const [showModal, setShowModal] = useState<'create' | 'edit' | 'delete' | 'reopen' | null>(null);
  const [selectedTask, setSelectedTask] = useState<any>(null);
  const [users, setUsers] = useState<any[]>([]);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    status: 'PENDING',
    priority: 'MEDIUM',
    deadline: '',
    assigneeId: ''
  });

  useEffect(() => {
    fetchTasks();
    fetchUsers();
  }, []);

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

  const handleExportTasks = async () => {
    try {
      toast.info('Generating... ');
      await downloadExcel('/tasks/reports/export', `Task_Reports_${Date.now()}.xlsx`, { scope: 'TEAM' });
      toast.success('Downloaded');
    } catch (err: any) {
      toast.error('Export Failed');
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await api.post('/tasks/create', formData);
      if (res.data.success) {
        setShowModal(null);
        fetchTasks();
        toast.success('Task deployed');
      }
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Deployment failed');
    }
  };

  const handleUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await api.put(`/tasks/${selectedTask.id}`, formData);
      if (res.data.success) {
        setShowModal(null);
        fetchTasks();
        toast.success('Parameters synced');
      }
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Sync failed');
    }
  };

  const handleDelete = async () => {
    try {
      const res = await api.delete(`/tasks/${selectedTask.id}`);
      if (res.data.success) {
        setShowModal(null);
        fetchTasks();
        toast.success('Task purged');
      }
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Purge failed');
    }
  };

  const handleReopen = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await api.post(`/tasks/${selectedTask.id}/reopen`, {
        newDeadline: formData.deadline,
        status: 'PENDING'
      });
      if (res.data.success) {
        setShowModal(null);
        fetchTasks();
        toast.success('Operation reactivated');
      }
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Reactivation failed');
    }
  };

  const filteredTasks = tasks.filter(t => filter === 'ALL' || t.status === filter);

  return (
    <div className="flex flex-col lg:flex-row min-h-screen bg-slate-950 text-slate-50">
      <Sidebar />
      
      <main className="flex-1 p-6 md:p-10 overflow-y-auto mt-16 lg:mt-0">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-slate-800 pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl md:text-4xl font-black tracking-tighter text-white uppercase italic">Task Oversight</h2>
            <p className="text-slate-400 mt-1 text-[10px] md:text-xs font-black uppercase tracking-[0.2em] opacity-60">Global regulation of assigned objectives.</p>
          </motion.div>
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 w-full md:w-auto">
            <div className="flex gap-3">
              <button 
                onClick={handleExportTasks}
                className="flex-1 sm:flex-none px-6 py-2.5 bg-slate-900 border border-slate-800 rounded-2xl flex items-center justify-center gap-2 hover:bg-slate-800 transition-all font-black text-[10px] uppercase tracking-widest text-slate-400"
              >
                <FileSpreadsheet size={16} />
                Export
              </button>
              <button 
                onClick={() => {
                  setFormData({ title: '', description: '', status: 'PENDING', priority: 'MEDIUM', deadline: '', assigneeId: '' });
                  setShowModal('create');
                }}
                className="flex-1 sm:flex-none px-6 py-2.5 bg-blue-600 text-white rounded-2xl flex items-center justify-center gap-2 hover:bg-blue-500 transition-all font-black text-[10px] uppercase tracking-widest shadow-lg shadow-blue-600/20"
              >
                Deploy +
              </button>
            </div>
            <div className="flex gap-1 bg-slate-950 p-1 rounded-xl border border-slate-800 overflow-x-auto custom-scrollbar no-scrollbar">
              {['ALL', 'PENDING', 'IN_PROGRESS', 'COMPLETED'].map((f) => (
                <button 
                  key={f}
                  onClick={() => setFilter(f)}
                  className={cn(
                    "px-4 py-2 rounded-lg text-[8px] font-black tracking-widest uppercase transition-all whitespace-nowrap",
                    filter === f ? "bg-slate-800 text-white" : "text-slate-600 hover:text-slate-400"
                  )}
                >
                  {f === 'IN_PROGRESS' ? 'ONGOING' : f}
                </button>
              ))}
            </div>
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6 md:gap-8">
          {filteredTasks.map((task, i) => (
            <motion.div 
              key={task.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="bg-slate-900/50 border border-slate-800 rounded-[2rem] p-8 hover:border-slate-700 transition-all group relative flex flex-col h-full backdrop-blur-xl"
            >
              <div className="absolute top-4 right-4 opacity-0 group-hover:opacity-100 transition-opacity flex gap-2">
                 <button 
                  onClick={() => {
                    setSelectedTask(task);
                    setFormData({
                      title: task.title,
                      description: task.description || '',
                      status: task.status,
                      priority: task.priority || 'MEDIUM',
                      deadline: task.deadline ? new Date(task.deadline).toISOString().split('T')[0] : '',
                      assigneeId: task.assigneeId || ''
                    });
                    setShowModal('edit');
                  }}
                  className="p-2 border border-[#444444] rounded text-[#888888] hover:text-[#E0E0E0]"
                >
                    <Edit3 size={14} />
                 </button>
                 <button 
                  onClick={() => { setSelectedTask(task); setShowModal('delete'); }}
                  className="p-2 border border-[#444444] rounded text-[#888888] hover:text-red-500"
                >
                    <Trash2 size={14} />
                 </button>
                 {task.status === 'COMPLETED' && (
                    <button 
                      onClick={() => {
                        setSelectedTask(task);
                        setFormData({ ...formData, deadline: '' });
                        setShowModal('reopen');
                      }}
                      className="p-2 border border-[#444444] rounded text-[#888888] hover:text-amber-500"
                      title="Reopen Task"
                    >
                      <RotateCcw size={14} />
                    </button>
                 )}
              </div>

              <div className="flex justify-between items-start mb-6">
                <div className="px-3 py-1 rounded-full text-[8px] font-black uppercase tracking-[0.2em] border border-slate-800 text-slate-500">
                   {task.status.replace('_', ' ')}
                </div>
                <div className="flex items-center gap-1.5 text-slate-600">
                   <Clock size={10} />
                   <span className="text-[9px] font-black uppercase tracking-tighter">
                      {task.deadline ? new Date(task.deadline).toLocaleDateString() : 'N/A'}
                   </span>
                </div>
              </div>

              <h4 className="text-xl font-black text-white mb-2 uppercase tracking-tight group-hover:text-blue-400 transition-colors">{task.title}</h4>
              <p className="text-slate-400 text-xs line-clamp-2 mb-8 flex-1 italic opacity-60">
                 {task.description || 'No instruction briefing recorded.'}
              </p>

              <div className="pt-6 border-t border-slate-800 space-y-4">
                 <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                       <div className="h-8 w-8 bg-[#444444]/20 border border-[#444444] rounded flex items-center justify-center font-bold text-xs">
                          {task.assignee?.name?.[0] || 'A'}
                       </div>
                       <div>
                          <p className="text-[10px] font-black text-white uppercase tracking-tighter">{task.assignee?.name || 'Unassigned'}</p>
                          <p className="text-[8px] font-black text-slate-600 uppercase tracking-widest">{task.assignee?.role || 'AGENT'}</p>
                       </div>
                    </div>
                    <div className="px-2 py-0.5 rounded-full text-[8px] font-black uppercase tracking-widest border border-slate-800 text-slate-500">
                      {task.priority || 'NORMAL'}
                    </div>
                 </div>
                 
                 {task.originalDeadline && (
                    <div className="p-3 bg-slate-950/50 border border-slate-800 rounded-xl flex justify-between items-center">
                       <span className="text-[8px] font-black text-slate-600 uppercase tracking-widest">Original Deadline</span>
                       <span className="text-[9px] font-bold text-rose-500/60 uppercase">{new Date(task.originalDeadline).toLocaleDateString()}</span>
                    </div>
                 )}
              </div>
            </motion.div>
          ))}
        </div>

        <AnimatePresence>
           {(showModal === 'create' || showModal === 'edit') && (
            <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-slate-950/80 backdrop-blur-md">
              <motion.div 
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="w-full max-w-xl bg-slate-900 border border-slate-800 rounded-[2.5rem] p-8 md:p-12 shadow-2xl overflow-y-auto max-h-[90vh]"
              >
                <h3 className="text-xl md:text-2xl font-black text-white uppercase tracking-tighter mb-10 italic">
                   {showModal === 'create' ? 'Deploy Objective' : 'Sync Parameters'}
                </h3>

                <form onSubmit={showModal === 'create' ? handleCreate : handleUpdate} className="space-y-6">
                    <div className="space-y-2">
                       <label className="text-[9px] font-black text-slate-600 uppercase tracking-widest ml-1">Objective Title</label>
                       <input 
                          type="text" required
                          className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-xs focus:border-blue-500/50 outline-none text-white transition-all shadow-inner"
                          value={formData.title}
                          onChange={e => setFormData({...formData, title: e.target.value})}
                       />
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                       <div className="space-y-2">
                          <label className="text-[9px] font-black text-slate-600 uppercase tracking-widest ml-1">Assigned Agent</label>
                          <select 
                             className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-xs outline-none text-white transition-all shadow-inner appearance-none"
                             required
                             value={formData.assigneeId}
                             onChange={e => setFormData({...formData, assigneeId: e.target.value})}
                          >
                             <option value="">SELECT AGENT</option>
                             {users.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}
                          </select>
                       </div>
                       <div className="space-y-2">
                          <label className="text-[9px] font-black text-slate-600 uppercase tracking-widest ml-1">Deadline Protocol</label>
                          <input 
                             type="date"
                             className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-xs outline-none text-white transition-all shadow-inner"
                             value={formData.deadline}
                             onChange={e => setFormData({...formData, deadline: e.target.value})}
                          />
                       </div>
                    </div>

                   <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <div className="space-y-2">
                         <label className="text-[9px] font-black text-slate-600 uppercase tracking-widest ml-1">Priority index</label>
                         <select 
                            className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-xs outline-none text-white transition-all shadow-inner appearance-none"
                            value={formData.priority}
                            onChange={e => setFormData({...formData, priority: e.target.value})}
                         >
                            <option value="LOW">LOW</option>
                            <option value="MEDIUM">MEDIUM</option>
                            <option value="HIGH">HIGH</option>
                            <option value="CRITICAL">CRITICAL</option>
                         </select>
                      </div>
                      <div className="space-y-2">
                         <label className="text-[9px] font-black text-slate-600 uppercase tracking-widest ml-1">Active Status</label>
                         <select 
                            className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-xs outline-none text-white transition-all shadow-inner appearance-none"
                            value={formData.status}
                            onChange={e => setFormData({...formData, status: e.target.value})}
                          >
                            <option value="PENDING">PENDING</option>
                            <option value="IN_PROGRESS">ONGOING</option>
                            <option value="COMPLETED">COMPLETED</option>
                         </select>
                      </div>
                   </div>

                    <div className="space-y-2">
                       <label className="text-[9px] font-black text-slate-600 uppercase tracking-widest ml-1">Mission Briefing</label>
                       <textarea 
                          className="w-full h-32 bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-xs focus:border-blue-500/50 outline-none text-white resize-none transition-all shadow-inner"
                          value={formData.description}
                          onChange={e => setFormData({...formData, description: e.target.value})}
                       />
                    </div>

                    <div className="flex flex-col sm:flex-row gap-4 pt-8 border-t border-slate-800">
                       <button type="button" onClick={() => setShowModal(null)} className="order-2 sm:order-1 flex-1 py-4 text-[10px] font-black uppercase text-slate-500 hover:text-white transition-all">Abort</button>
                       <button type="submit" className="order-1 sm:order-2 flex-1 py-4 bg-blue-600 text-white text-[10px] font-black uppercase tracking-widest rounded-2xl transition-all shadow-lg shadow-blue-600/20 active:scale-95">Synchronize</button>
                    </div>
                </form>
              </motion.div>
            </div>
          )}

           {showModal === 'reopen' && selectedTask && (
              <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-slate-950/80 backdrop-blur-md">
                 <motion.div 
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="w-full max-w-md bg-slate-900 border border-amber-500/20 rounded-[2.5rem] p-10 md:p-12 shadow-2xl"
                 >
                    <div className="h-20 w-20 bg-amber-500/10 border border-amber-500/20 rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-inner">
                       <RotateCcw size={32} className="text-amber-500" />
                    </div>
                    <h3 className="text-2xl font-black text-white uppercase tracking-tighter text-center mb-2 italic">Reactivate Objective</h3>
                    <p className="text-[10px] text-slate-500 uppercase text-center mb-10 font-bold">Override completion and establish new target deadline.</p>

                    <form onSubmit={handleReopen} className="space-y-8">
                       <div className="space-y-2">
                          <label className="text-[9px] font-black text-slate-600 uppercase tracking-widest ml-1">New Deadline Protocol</label>
                          <input 
                             type="date" required
                             className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-xs outline-none text-white shadow-inner"
                             value={formData.deadline}
                             onChange={e => setFormData({...formData, deadline: e.target.value})}
                          />
                       </div>
                       <div className="flex flex-col sm:flex-row gap-4 pt-6 border-t border-slate-800">
                         <button type="button" onClick={() => setShowModal(null)} className="order-2 sm:order-1 flex-1 py-4 text-[10px] font-black uppercase text-slate-500 hover:text-white transition-all">Abort</button>
                         <button type="submit" className="order-1 sm:order-2 flex-1 py-4 bg-amber-600 text-white text-[10px] font-black uppercase tracking-widest rounded-2xl shadow-lg shadow-amber-600/20 transition-all active:scale-95">Reactivate</button>
                       </div>
                    </form>
                 </motion.div>
              </div>
           )}

          {showModal === 'delete' && selectedTask && (
             <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-slate-950/90 backdrop-blur-xl">
                <motion.div initial={{ scale: 0.95 }} animate={{ scale: 1 }} className="bg-slate-900 border border-rose-500/20 rounded-[2.5rem] p-10 md:p-12 text-center max-w-sm w-full shadow-2xl">
                   <div className="h-20 w-20 bg-rose-500/10 border border-rose-500/20 rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-inner">
                      <Trash2 size={32} className="text-rose-500" />
                   </div>
                   <h3 className="text-2xl font-black text-white uppercase tracking-tighter mb-3">Purge Assignment?</h3>
                   <p className="text-xs text-slate-400 font-medium leading-relaxed mb-8 italic">This action will permanently erase the objective from the tactical mainframe.</p>
                   <div className="flex gap-4">
                      <button onClick={() => setShowModal(null)} className="flex-1 py-4 text-[10px] font-black uppercase text-slate-500 hover:text-white transition-all">Abort</button>
                      <button onClick={handleDelete} className="flex-1 py-4 bg-rose-600 text-white text-[10px] font-black uppercase rounded-2xl shadow-lg shadow-rose-600/20 transition-all active:scale-95">Purge</button>
                   </div>
                </motion.div>
             </div>
          )}
        </AnimatePresence>
      </main>
    </div>
  );
}
