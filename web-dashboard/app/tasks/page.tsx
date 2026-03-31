'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { CheckSquare, Clock, User, AlertCircle, ExternalLink, Filter, Search, ChevronRight, Plus, X, Trash2, Edit3 } from 'lucide-react';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';

export default function TasksPage() {
  const [tasks, setTasks] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('ALL');
  const [showModal, setShowModal] = useState<'create' | 'edit' | 'delete' | null>(null);
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

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await api.post('/tasks/create', formData);
      if (res.data.success) {
        setShowModal(null);
        fetchTasks();
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to create task');
    }
  };

  const handleUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await api.put(`/tasks/${selectedTask.id}`, formData);
      if (res.data.success) {
        setShowModal(null);
        fetchTasks();
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to update task');
    }
  };

  const handleDelete = async () => {
    try {
      const res = await api.delete(`/tasks/${selectedTask.id}`);
      if (res.data.success) {
        setShowModal(null);
        fetchTasks();
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to delete task');
    }
  };

  const filteredTasks = tasks.filter(t => filter === 'ALL' || t.status === filter);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'COMPLETED': return 'text-emerald-500 bg-emerald-500/10 border-emerald-500/20';
      case 'IN_PROGRESS': return 'text-blue-500 bg-blue-500/10 border-blue-500/20';
      case 'PENDING': return 'text-amber-500 bg-amber-500/10 border-amber-500/20';
      default: return 'text-slate-500 bg-slate-500/10 border-slate-500/20';
    }
  };

  return (
    <div className="flex min-h-screen bg-slate-950 text-slate-50">
      <Sidebar />
      
      <main className="flex-1 p-8 overflow-y-auto">
        <header className="mb-10 flex justify-between items-center">
          <div>
            <h2 className="text-3xl font-black tracking-tight text-white uppercase tracking-tighter">Task Command Center</h2>
            <p className="text-slate-400 mt-1 font-medium italic">Global tracking and regulation of active assignments.</p>
          </div>
          <div className="flex items-center gap-4">
            <button 
              onClick={() => {
                setFormData({ title: '', description: '', status: 'PENDING', priority: 'MEDIUM', deadline: '', assigneeId: '' });
                setShowModal('create');
              }}
              className="px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-2xl text-[10px] font-black uppercase tracking-widest text-white shadow-lg shadow-blue-600/20 transition-all active:scale-95 flex items-center gap-2"
            >
              <Plus size={16} /> New Deployment
            </button>
            <div className="flex gap-2 bg-slate-900 border border-slate-800 p-1 rounded-xl">
              {['ALL', 'PENDING', 'IN_PROGRESS', 'COMPLETED'].map((f) => (
                <button 
                  key={f}
                  onClick={() => setFilter(f)}
                  className={cn(
                    "px-4 py-2 rounded-lg text-[10px] font-black tracking-widest uppercase transition-all",
                    filter === f ? "bg-slate-800 text-white shadow-md" : "text-slate-500 hover:text-slate-300"
                  )}
                >
                  {f === 'IN_PROGRESS' ? 'ONGOING' : f}
                </button>
              ))}
            </div>
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredTasks.map((task, i) => (
            <motion.div 
              key={task.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="bg-slate-900 border border-slate-800 rounded-3xl p-6 hover:border-slate-700 transition-all group relative overflow-hidden"
            >
              <div className="absolute top-0 right-0 p-4 opacity-0 group-hover:opacity-100 transition-opacity flex gap-2">
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
                  className="p-2 bg-slate-950/50 border border-slate-800 rounded-lg hover:text-blue-400 transition-colors"
                >
                    <Edit3 size={16} />
                 </button>
                 <button 
                  onClick={() => {
                    setSelectedTask(task);
                    setShowModal('delete');
                  }}
                  className="p-2 bg-slate-950/50 border border-slate-800 rounded-lg hover:text-rose-400 transition-colors"
                >
                    <Trash2 size={16} />
                 </button>
              </div>

              <div className="flex justify-between items-start mb-4">
                <span className={cn("px-2.5 py-1 rounded-lg text-[10px] font-black uppercase tracking-wider border", getStatusColor(task.status))}>
                   {task.status.replace('_', ' ')}
                </span>
                <div className="flex items-center gap-1.5 text-slate-500">
                   <Clock size={12} />
                   <span className="text-[10px] font-bold uppercase tracking-tighter">
                      {task.deadline ? new Date(task.deadline).toLocaleDateString() : 'No Deadline'}
                   </span>
                </div>
              </div>

              <h4 className="text-lg font-black text-white mb-2 leading-tight group-hover:text-blue-400 transition-colors">{task.title}</h4>
              <p className="text-slate-500 text-xs line-clamp-2 mb-6 font-medium italic">
                 {task.description || 'No technical instructions provided for this assignment.'}
              </p>

              <div className="flex items-center justify-between pt-4 border-t border-slate-800/50">
                 <div className="flex items-center gap-2">
                    <div className="h-8 w-8 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center font-bold text-[10px] text-slate-400">
                       {task.assignee?.name?.[0] || 'A'}
                    </div>
                    <div>
                       <p className="text-[10px] font-black text-slate-200 uppercase tracking-tight">{task.assignee?.name || 'Unassigned Agent'}</p>
                       <p className="text-[8px] font-black text-slate-600 uppercase tracking-widest">{task.assignee?.role || 'MEMBER'}</p>
                    </div>
                 </div>
                 <div className={cn(
                    "px-2 py-0.5 rounded-md text-[8px] font-black uppercase tracking-[0.2em] border",
                    task.priority === 'CRITICAL' ? "text-rose-500 bg-rose-500/5 border-rose-500/10" :
                    task.priority === 'HIGH' ? "text-orange-500 bg-orange-500/5 border-orange-500/10" :
                    "text-slate-500 bg-slate-500/5 border-slate-500/10"
                 )}>
                    {task.priority || 'NORMAL'}
                 </div>
              </div>
            </motion.div>
          ))}
        </div>

        {filteredTasks.length === 0 && !loading && (
          <div className="p-32 text-center text-slate-500 border-2 border-dashed border-slate-800 rounded-[3rem]">
            <CheckSquare size={48} className="mx-auto mb-4 opacity-10" />
            <p className="font-bold text-lg uppercase tracking-widest text-slate-300">Zero Operations Identified</p>
            <p className="text-sm mt-1">Assignments tracking will initialize once operations begin.</p>
          </div>
        )}

        <AnimatePresence>
          {(showModal === 'create' || showModal === 'edit') && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-xl">
              <motion.div 
                initial={{ opacity: 0, scale: 0.9, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.9, y: 20 }}
                className="relative w-full max-w-xl bg-slate-900 border border-slate-700/50 rounded-[3rem] shadow-2xl overflow-hidden flex flex-col"
              >
                <div className="p-10 pb-4 flex justify-between items-start border-b border-slate-800 bg-slate-900/50">
                   <div>
                      <h3 className="text-2xl font-black text-white uppercase tracking-tighter">
                         {showModal === 'create' ? 'Deploy New Task' : 'Modify Assignment'}
                      </h3>
                      <p className="text-[10px] font-black text-rose-500/60 uppercase tracking-[0.4em] mt-1">Operational Protocol v1.4</p>
                   </div>
                   <button onClick={() => setShowModal(null)} className="p-3 bg-slate-950 border border-slate-800 rounded-2xl text-slate-500 hover:text-white transition-all">
                      <X size={20} />
                   </button>
                </div>

                <form onSubmit={showModal === 'create' ? handleCreate : handleUpdate} className="p-10 space-y-6 overflow-y-auto max-h-[70vh] custom-scrollbar">
                   <div className="space-y-2">
                      <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Task Objective</label>
                      <input 
                         type="text" required
                         className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-bold text-white shadow-inner"
                         placeholder="Brief title for the task..."
                         value={formData.title}
                         onChange={e => setFormData({...formData, title: e.target.value})}
                      />
                   </div>

                   <div className="grid grid-cols-2 gap-6">
                      <div className="space-y-2">
                         <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Assigned Agent</label>
                         <select 
                            className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-bold text-white appearance-none shadow-inner"
                            required
                            value={formData.assigneeId}
                            onChange={e => setFormData({...formData, assigneeId: e.target.value})}
                         >
                            <option value="">SELECT AGENT</option>
                            {users.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}
                         </select>
                      </div>
                      <div className="space-y-2">
                         <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Deadline Date</label>
                         <input 
                            type="date"
                            className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-bold text-white shadow-inner"
                            value={formData.deadline}
                            onChange={e => setFormData({...formData, deadline: e.target.value})}
                         />
                      </div>
                   </div>

                   <div className="grid grid-cols-2 gap-6">
                      <div className="space-y-2">
                         <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Priority Index</label>
                         <select 
                            className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-bold text-white appearance-none shadow-inner"
                            value={formData.priority}
                            onChange={e => setFormData({...formData, priority: e.target.value})}
                         >
                            <option value="LOW">LOW PRIORITY</option>
                            <option value="MEDIUM">MEDIUM PRIORITY</option>
                            <option value="HIGH">HIGH PRIORITY</option>
                            <option value="CRITICAL">CRITICAL LEVEL</option>
                         </select>
                      </div>
                      <div className="space-y-2">
                         <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Active Status</label>
                         <select 
                            className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-sm focus:outline-none focus:ring-4 focus:ring-emerald-500/10 focus:border-emerald-500/50 transition-all font-bold text-white appearance-none shadow-inner"
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
                      <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Detailed Instructions</label>
                      <textarea 
                         className="w-full h-32 bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-medium text-slate-300 resize-none shadow-inner"
                         placeholder="Technical description and tactical steps..."
                         value={formData.description}
                         onChange={e => setFormData({...formData, description: e.target.value})}
                      />
                   </div>

                   <div className="flex gap-4 pt-4 border-t border-slate-800 mt-2">
                      <button 
                         type="button" onClick={() => setShowModal(null)}
                         className="flex-1 px-6 py-4 bg-slate-800 hover:bg-slate-750 text-white rounded-2xl font-bold transition-all active:scale-95"
                      >
                         Abort Operation
                      </button>
                      <button 
                         type="submit"
                         className="flex-1 px-6 py-4 bg-blue-600 hover:bg-blue-500 text-white rounded-2xl font-bold transition-all shadow-lg shadow-blue-600/20 active:scale-95"
                      >
                         {showModal === 'create' ? 'Launch Deployment' : 'Sync Changes'}
                      </button>
                   </div>
                </form>
              </motion.div>
            </div>
          )}

          {showModal === 'delete' && selectedTask && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-xl">
               <motion.div 
                  initial={{ scale: 0.9, opacity: 0, y: 20 }}
                  animate={{ scale: 1, opacity: 1, y: 0 }}
                  exit={{ scale: 0.9, opacity: 0, y: 20 }}
                  className="relative w-full max-w-md bg-slate-900 border border-rose-500/20 rounded-[3rem] shadow-2xl p-10 text-center"
               >
                  <div className="h-20 w-20 bg-rose-500/10 border border-rose-500/20 rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-inner">
                     <Trash2 size={32} className="text-rose-500" />
                  </div>
                  <h3 className="text-2xl font-black text-white uppercase tracking-tighter">Discard Task?</h3>
                  <p className="text-slate-400 text-sm mt-3 leading-relaxed font-medium">
                     You are about to terminate the assignment <strong className="text-rose-400">"{selectedTask.title}"</strong>. This protocol is irreversible.
                  </p>

                  <div className="flex gap-4 mt-8">
                     <button 
                        onClick={() => setShowModal(null)}
                        className="flex-1 px-6 py-4 bg-slate-800 hover:bg-slate-750 text-white rounded-2xl font-bold transition-all"
                     >
                        Abort
                     </button>
                     <button 
                        onClick={handleDelete}
                        className="flex-1 px-6 py-4 bg-rose-600 hover:bg-rose-500 text-white rounded-2xl font-black uppercase tracking-widest transition-all shadow-lg shadow-rose-600/20 active:scale-95"
                     >
                        Discard
                     </button>
                  </div>
               </motion.div>
            </div>
          )}
        </AnimatePresence>
      </main>
    </div>
  );
}
