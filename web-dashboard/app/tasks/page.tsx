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
    <div className="flex flex-col lg:flex-row min-h-screen bg-[#131313] text-[#FFFFFF]">
      <Sidebar />
      
      <main className="flex-1 p-6 md:p-10 overflow-y-auto mt-16 lg:mt-0 custom-scrollbar no-scrollbar">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-[#4B4A48] pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl md:text-5xl font-black tracking-tighter text-[#FFFFFF] uppercase italic">Task Oversight</h2>
            <p className="text-[#A4A4A4] mt-1 text-[10px] md:text-xs font-black uppercase tracking-[0.2em] opacity-60">Global regulation of assigned objectives.</p>
          </motion.div>
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-4 w-full md:w-auto">
            <div className="flex gap-3">
              <button 
                onClick={handleExportTasks}
                className="flex-1 sm:flex-none px-6 py-2.5 bg-transparent border border-[#4B4A48] rounded flex items-center justify-center gap-2 hover:bg-[#EFD395]/10 text-[#A4A4A4] hover:text-[#EFD395] transition-all font-black text-[10px] uppercase tracking-widest shadow-xl active:scale-95"
              >
                <FileSpreadsheet size={16} />
                Export
              </button>
              <button 
                onClick={() => {
                  setFormData({ title: '', description: '', status: 'PENDING', priority: 'MEDIUM', deadline: '', assigneeId: '' });
                  setShowModal('create');
                }}
                className="flex-1 sm:flex-none px-6 py-2.5 bg-[#EFD395] text-[#131313] rounded flex items-center justify-center gap-2 hover:bg-white transition-all font-black text-[10px] uppercase tracking-widest shadow-lg active:scale-95"
              >
                Deploy +
              </button>
            </div>
            <div className="flex gap-1 bg-[#131313] p-1 rounded border border-[#4B4A48] overflow-x-auto custom-scrollbar no-scrollbar">
              {['ALL', 'PENDING', 'IN_PROGRESS', 'COMPLETED'].map((f) => (
                <button 
                  key={f}
                  onClick={() => setFilter(f)}
                  className={cn(
                    "px-4 py-2 rounded text-[8px] font-black tracking-widest uppercase transition-all whitespace-nowrap",
                    filter === f ? "bg-[#EFD395] text-[#131313]" : "text-[#777674] hover:text-[#A4A4A4]"
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
              className="bg-[#262625] border border-[#4B4A48] rounded p-8 hover:border-[#EFD395]/30 transition-all group relative flex flex-col h-full"
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
                  className="p-2 bg-[#131313] border border-[#4B4A48] rounded text-[#777674] hover:text-[#FFFFFF]"
                >
                    <Edit3 size={14} />
                 </button>
                 <button 
                  onClick={() => { setSelectedTask(task); setShowModal('delete'); }}
                  className="p-2 bg-[#131313] border border-[#4B4A48] rounded text-[#777674] hover:text-red-500"
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
                      className="p-2 bg-[#131313] border border-[#4B4A48] rounded text-[#777674] hover:text-[#EFD395]"
                      title="Reopen Task"
                    >
                      <RotateCcw size={14} />
                    </button>
                 )}
              </div>

              <div className="flex justify-between items-start mb-6">
                <div className="px-3 py-1 rounded text-[8px] font-black uppercase tracking-[0.2em] border border-[#4B4A48] text-[#777674] bg-[#131313]">
                   {task.status.replace('_', ' ')}
                </div>
                <div className="flex items-center gap-1.5 text-[#A4A4A4]">
                   <Clock size={10} className="text-[#EFD395]" />
                   <span className="text-[9px] font-black uppercase tracking-widest italic">
                      {task.deadline ? new Date(task.deadline).toLocaleDateString() : 'N/A'}
                   </span>
                </div>
              </div>

              <h4 className="text-xl font-black text-white mb-2 uppercase tracking-tight italic group-hover:text-[#EFD395] transition-colors">{task.title}</h4>
              <p className="text-[#A4A4A4] text-xs line-clamp-2 mb-8 flex-1 italic opacity-60">
                 {task.description || 'No instruction briefing recorded.'}
              </p>

              <div className="pt-6 border-t border-[#4B4A48] space-y-4">
                 <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                       <div className="h-9 w-9 bg-[#131313] border border-[#4B4A48] rounded flex items-center justify-center font-black text-xs text-[#EFD395] italic">
                          {task.assignee?.name?.[0] || 'A'}
                       </div>
                       <div>
                          <p className="text-[10px] font-black text-white uppercase tracking-tighter italic">{task.assignee?.name || 'Unassigned'}</p>
                          <p className="text-[8px] font-black text-[#777674] uppercase tracking-[0.2em]">{task.assignee?.role || 'AGENT'}</p>
                       </div>
                    </div>
                    <div className="flex items-center gap-2 px-2.5 py-1 rounded border border-[#4B4A48] text-[8px] font-black uppercase tracking-widest text-[#A4A4A4] bg-[#131313]">
                      <Shield size={10} className={cn(task.priority === 'CRITICAL' ? "text-red-500" : "text-[#EFD395]")} />
                      {task.priority || 'NORMAL'}
                    </div>
                 </div>
                 
                 {task.originalDeadline && (
                    <div className="p-3 bg-[#131313] border border-[#4B4A48] rounded flex justify-between items-center shadow-inner">
                       <span className="text-[8px] font-black text-[#777674] uppercase tracking-widest">Original Deadline</span>
                       <span className="text-[9px] font-black text-red-500/60 uppercase italic tracking-tighter">{new Date(task.originalDeadline).toLocaleDateString()}</span>
                    </div>
                 )}
              </div>
            </motion.div>
          ))}
        </div>

        <AnimatePresence>
           {(showModal === 'create' || showModal === 'edit') && (
            <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-black/80 backdrop-blur-md">
              <motion.div 
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="w-full max-w-xl bg-[#262625] border border-[#4B4A48] rounded p-8 md:p-12 shadow-2xl overflow-y-auto max-h-[90vh] custom-scrollbar no-scrollbar"
              >
                <h3 className="text-xl md:text-3xl font-black text-white uppercase tracking-tighter mb-10 italic">
                   {showModal === 'create' ? 'Deploy Objective' : 'Sync Parameters'}
                </h3>

                <form onSubmit={showModal === 'create' ? handleCreate : handleUpdate} className="space-y-8">
                    <div className="space-y-3">
                       <label className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] ml-1">Objective Title</label>
                       <input 
                          type="text" required
                          className="w-full bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 text-xs focus:border-[#EFD395] outline-none text-white transition-all shadow-inner font-black uppercase italic"
                          value={formData.title}
                          onChange={e => setFormData({...formData, title: e.target.value})}
                       />
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                       <div className="space-y-3">
                          <label className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] ml-1">Assigned Agent</label>
                          <select 
                             className="w-full bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 text-xs outline-none text-white transition-all shadow-inner appearance-none font-black italic"
                             required
                             value={formData.assigneeId}
                             onChange={e => setFormData({...formData, assigneeId: e.target.value})}
                          >
                             <option value="">SELECT AGENT</option>
                             {users.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}
                          </select>
                       </div>
                       <div className="space-y-3">
                          <label className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] ml-1">Deadline Protocol</label>
                          <input 
                             type="date"
                             className="w-full bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 text-xs outline-none text-white transition-all shadow-inner font-black italic"
                             value={formData.deadline}
                             onChange={e => setFormData({...formData, deadline: e.target.value})}
                          />
                       </div>
                    </div>

                   <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                      <div className="space-y-3">
                         <label className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] ml-1">Priority index</label>
                         <select 
                            className="w-full bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 text-xs outline-none text-white transition-all shadow-inner appearance-none font-black italic"
                            value={formData.priority}
                            onChange={e => setFormData({...formData, priority: e.target.value})}
                         >
                            <option value="LOW">LOW</option>
                            <option value="MEDIUM">MEDIUM</option>
                            <option value="HIGH">HIGH</option>
                            <option value="CRITICAL">CRITICAL</option>
                         </select>
                      </div>
                      <div className="space-y-3">
                         <label className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] ml-1">Active Status</label>
                         <select 
                            className="w-full bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 text-xs outline-none text-white transition-all shadow-inner appearance-none font-black italic"
                            value={formData.status}
                            onChange={e => setFormData({...formData, status: e.target.value})}
                          >
                            <option value="PENDING">PENDING</option>
                            <option value="IN_PROGRESS">ONGOING</option>
                            <option value="COMPLETED">COMPLETED</option>
                         </select>
                      </div>
                   </div>

                    <div className="space-y-3">
                       <label className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] ml-1">Mission Briefing</label>
                       <textarea 
                          className="w-full h-36 bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 text-xs focus:border-[#EFD395] outline-none text-white resize-none transition-all shadow-inner italic"
                          value={formData.description}
                          onChange={e => setFormData({...formData, description: e.target.value})}
                       />
                    </div>

                    <div className="flex flex-col sm:flex-row gap-6 pt-10 border-t border-[#4B4A48]">
                       <button type="button" onClick={() => setShowModal(null)} className="order-2 sm:order-1 flex-1 py-4 text-[10px] font-black uppercase tracking-[0.3em] text-[#777674] hover:text-red-500 transition-colors">Abort</button>
                       <button type="submit" className="order-1 sm:order-2 flex-1 py-4 bg-[#EFD395] text-[#131313] text-[10px] font-black uppercase tracking-[0.3em] rounded transition-all active:scale-95 shadow-xl">Synchronize</button>
                    </div>
                </form>
              </motion.div>
            </div>
          )}

           {showModal === 'reopen' && selectedTask && (
              <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-black/80 backdrop-blur-md">
                 <motion.div 
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="w-full max-w-md bg-[#262625] border border-[#EFD395]/20 rounded p-10 md:p-14 shadow-2xl"
                 >
                    <div className="h-20 w-20 bg-[#EFD395]/10 border border-[#EFD395]/20 rounded flex items-center justify-center mx-auto mb-8 shadow-inner shadow-[#EFD395]/5">
                       <RotateCcw size={40} className="text-[#EFD395]" />
                    </div>
                    <h3 className="text-2xl md:text-3xl font-black text-white uppercase tracking-tighter text-center mb-4 italic">Reactivate Objective</h3>
                    <p className="text-[10px] text-[#A4A4A4] uppercase text-center mb-12 font-black tracking-[0.2em] italic pr-4 pl-4 opacity-70">Override completion and establish new target deadline.</p>

                    <form onSubmit={handleReopen} className="space-y-10">
                       <div className="space-y-3">
                          <label className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] ml-1">New Deadline Protocol</label>
                          <input 
                             type="date" required
                             className="w-full bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 text-xs outline-none text-white shadow-inner font-black italic"
                             value={formData.deadline}
                             onChange={e => setFormData({...formData, deadline: e.target.value})}
                          />
                       </div>
                       <div className="flex flex-col sm:flex-row gap-4 pt-10 border-t border-[#4B4A48]">
                         <button type="button" onClick={() => setShowModal(null)} className="order-2 sm:order-1 flex-1 py-4 text-[10px] font-black uppercase tracking-[0.3em] text-[#777674] hover:text-[#FFFFFF] transition-all">Abort</button>
                         <button type="submit" className="order-1 sm:order-2 flex-1 py-4 bg-[#EFD395] text-[#131313] text-[10px] font-black uppercase tracking-[0.3em] rounded shadow-lg active:scale-95 transition-all">Reactivate</button>
                       </div>
                    </form>
                 </motion.div>
              </div>
           )}

          {showModal === 'delete' && selectedTask && (
             <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-black/90 backdrop-blur-xl">
                 <motion.div initial={{ scale: 0.95 }} animate={{ scale: 1 }} className="bg-[#262625] border border-red-500/20 rounded p-10 md:p-14 text-center max-w-sm w-full shadow-2xl">
                    <div className="h-20 w-20 bg-red-500/10 border border-red-500/20 rounded flex items-center justify-center mx-auto mb-8 shadow-inner shadow-red-500/5">
                       <Trash2 size={40} className="text-red-500" />
                    </div>
                    <h3 className="text-2xl font-black text-white uppercase tracking-tighter mb-4 italic">Purge Assignment?</h3>
                    <p className="text-[10px] text-[#A4A4A4] font-black uppercase tracking-[0.2em] leading-relaxed mb-12 italic opacity-60">This action will permanently erase the objective from the tactical mainframe. Recovery is not possible.</p>
                    <div className="flex gap-4">
                       <button onClick={() => setShowModal(null)} className="flex-1 py-4 text-[10px] font-black uppercase tracking-[0.2em] text-[#777674] hover:text-white transition-all">Abort</button>
                       <button onClick={handleDelete} className="flex-1 py-4 bg-red-600 text-white text-[10px] font-black uppercase tracking-[0.2em] rounded shadow-lg active:scale-95 transition-all">Purge</button>
                    </div>
                 </motion.div>
              </div>
          )}
        </AnimatePresence>
      </main>
    </div>
  );
}
