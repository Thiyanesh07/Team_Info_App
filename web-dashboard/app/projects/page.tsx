'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api, { downloadExcel } from '@/lib/api';
import { Rocket, Target, Users, Clock, Activity, Hexagon, Edit3, Trash2, FileSpreadsheet, X, Info, Shield, ExternalLink } from 'lucide-react';
import { toast } from 'sonner';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';

export default function ProjectsPage() {
  const [projects, setProjects] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedProject, setSelectedProject] = useState<any>(null);
  const [showDetails, setShowDetails] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [showCreate, setShowCreate] = useState(false);
  const [showDelete, setShowDelete] = useState(false);
  const [users, setUsers] = useState<any[]>([]);
  const [formData, setFormData] = useState({ 
    status: 'ONGOING', 
    projectName: '', 
    problemStatement: '',
    assignedCaptainId: '',
    memberIds: [] as string[]
  });

  useEffect(() => {
    fetchProjects();
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

  const fetchProjects = async () => {
    try {
      const res = await api.get('/team-projects');
      if (res.data.success) {
        setProjects(res.data.data);
      }
    } catch (err) {
      console.error('Fetch projects error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleExportProjects = async () => {
    try {
      toast.info('Generating... ');
      await downloadExcel('/export/projects', `Projects_${Date.now()}.xlsx`, { scope: 'TEAM' });
      toast.success('Downloaded');
    } catch (err: any) {
      toast.error('Export Failed');
    }
  };

  const openDetails = async (projectId: string) => {
    try {
      const res = await api.get(`/team-projects/${projectId}`);
      if (res.data.success) {
        setSelectedProject(res.data.data);
        setShowDetails(true);
      }
    } catch (err) {
      console.error('Fetch project details error:', err);
    }
  };

  const handleUpdate = async (e: any) => {
    e.preventDefault();
    try {
      const res = await api.put(`/admin/manage/projects/${selectedProject.id}`, {
        projectName: formData.projectName,
        status: formData.status,
        problemStatement: formData.problemStatement,
        assignedCaptainId: formData.assignedCaptainId,
        memberIds: formData.memberIds
      });
      if (res.data.success) {
        setShowEdit(false);
        fetchProjects();
        toast.success('Sync complete');
      }
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Failed to update');
    }
  };

  const handleCreate = async (e: any) => {
    e.preventDefault();
    try {
      const res = await api.post('/admin/manage/projects', {
        projectName: formData.projectName,
        status: formData.status,
        problemStatement: formData.problemStatement,
        assignedCaptainId: formData.assignedCaptainId,
        memberIds: formData.memberIds
      });
      if (res.data.success) {
        setShowCreate(false);
        fetchProjects();
        toast.success('Initiative launched');
      }
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Failed to create');
    }
  };

  const handleDelete = async () => {
    try {
      const res = await api.delete(`/admin/manage/projects/${selectedProject.id}`);
      if (res.data.success) {
        setShowDelete(false);
        fetchProjects();
        toast.success('Purge complete');
      }
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Failed to delete');
    }
  };

  return (
    <div className="flex flex-col lg:flex-row min-h-screen bg-[#121212] text-[#E0E0E0]">
      <Sidebar />
      
      <main className="flex-1 p-6 md:p-10 mt-16 lg:mt-0">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-[#444444] pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl md:text-4xl font-black tracking-tighter text-[#E0E0E0] uppercase italic">Project Oversight</h2>
            <p className="text-[#B0B0B0] mt-1 text-[10px] md:text-xs font-bold uppercase tracking-[0.2em] opacity-60">Global monitoring and regulation.</p>
          </motion.div>
          <div className="flex gap-3 w-full md:w-auto">
            <button 
              onClick={handleExportProjects}
              className="flex-1 md:flex-none px-4 py-2 bg-transparent border border-[#444444] rounded-md flex items-center justify-center gap-2 hover:bg-[#444444]/20 transition-all font-black text-[10px] uppercase tracking-widest text-[#B0B0B0]"
            >
              <FileSpreadsheet size={16} />
              Export
            </button>
            <button 
              onClick={() => {
                setFormData({ 
                  status: 'NOT_STARTED', 
                  projectName: '', 
                  problemStatement: '',
                  assignedCaptainId: '',
                  memberIds: []
                });
                setShowCreate(true);
              }}
              className="flex-1 md:flex-none px-4 py-2 bg-[#E0E0E0] text-[#121212] rounded-md flex items-center justify-center gap-2 hover:bg-white transition-all font-black text-[10px] uppercase tracking-widest"
            >
              Initiate +
            </button>
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6 md:gap-8">
          {projects.map((project, i) => (
            <motion.div 
              key={project.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="bg-transparent border border-[#444444] rounded-lg p-6 md:p-8 hover:border-[#888888] transition-all group flex flex-col h-full relative"
            >
              <div className="absolute top-4 right-4 flex gap-2 z-20 opacity-0 group-hover:opacity-100 transition-opacity">
                <button 
                  onClick={(e) => { 
                    e.stopPropagation(); 
                    setSelectedProject(project); 
                    setFormData({ 
                      status: project.status, 
                      projectName: project.projectName || project.title, 
                      problemStatement: project.problemStatement || project.description || '',
                      assignedCaptainId: project.assignedCaptain?.id || '',
                      memberIds: project.members?.map((m: any) => m.userId || m.id) || []
                    });
                    setShowEdit(true); 
                  }}
                  className="p-2 bg-[#121212] border border-[#444444] rounded text-[#888888] hover:text-[#E0E0E0] transition-all"
                >
                  <Edit3 size={14} />
                </button>
                <button 
                  onClick={(e) => { 
                    e.stopPropagation(); 
                    setSelectedProject(project); 
                    setShowDelete(true); 
                  }}
                  className="p-2 bg-[#121212] border border-[#444444] rounded text-[#888888] hover:text-red-500 transition-all"
                >
                  <Trash2 size={14} />
                </button>
              </div>

              <div className="flex justify-between items-start mb-6">
                <div className="p-2 border border-[#444444] rounded-md text-[#888888]">
                  <Rocket size={20} />
                </div>
                <div className="px-3 py-1 rounded-sm text-[8px] font-black uppercase tracking-[0.2em] border border-[#444444] text-[#888888]">
                  {project.status.replace('_', ' ')}
                </div>
              </div>

              <h3 className="text-xl font-black text-[#E0E0E0] mb-2 uppercase tracking-tight">
                {project.projectName || project.title}
              </h3>
              <p className="text-xs text-[#B0B0B0] line-clamp-2 mb-8 flex-1 italic opacity-60">
                {project.problemStatement || project.description || 'No briefing documented.'}
              </p>

              <div className="pt-6 border-t border-[#444444] space-y-3">
                 <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest text-[#888888]">
                   <span>Lead</span>
                   <span className="text-[#E0E0E0]">{project.assignedCaptain?.name || '---'}</span>
                 </div>
                 <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest text-[#888888]">
                   <span>Deployment</span>
                   <span className="text-[#E0E0E0]">{project.members?.length || 0} Agents</span>
                 </div>
              </div>

              <button 
                onClick={() => openDetails(project.id)}
                className="w-full mt-6 py-3 bg-transparent border border-[#444444] rounded text-[9px] font-black uppercase tracking-[0.2em] text-[#B0B0B0] hover:bg-[#444444]/10 transition-all"
              >
                Records
              </button>
            </motion.div>
          ))}
        </div>

        <AnimatePresence>
          {showDetails && selectedProject && (
            <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-black/60 backdrop-blur-sm">
              <motion.div 
                initial={{ opacity: 0, scale: 0.98 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.98 }}
                className="bg-[#121212] border border-[#444444] rounded-lg w-full max-w-4xl max-h-[90vh] overflow-hidden shadow-2xl flex flex-col"
              >
                <div className="p-6 md:p-8 border-b border-[#444444] flex justify-between items-start">
                   <div className="flex gap-4 items-center">
                      <Target size={24} className="text-[#888888]" />
                      <div className="overflow-hidden">
                         <p className="text-[10px] font-black text-[#888888] uppercase tracking-[0.3em]">{selectedProject.status}</p>
                         <h2 className="text-lg md:text-2xl font-black text-[#E0E0E0] uppercase tracking-tighter truncate">{selectedProject.projectName}</h2>
                      </div>
                   </div>
                   <button onClick={() => setShowDetails(false)} className="p-2 text-[#888888] hover:text-[#E0E0E0] flex-shrink-0">
                      <X size={20} />
                   </button>
                </div>

                <div className="flex-1 overflow-y-auto p-6 md:p-8 space-y-8 lg:space-y-0 lg:grid lg:grid-cols-3 lg:gap-10">
                   <div className="lg:col-span-2 space-y-8">
                      <div>
                         <h4 className="text-[9px] font-black text-[#444444] uppercase tracking-[0.3em] mb-3">Mission Briefing</h4>
                         <p className="text-[#B0B0B0] text-sm leading-relaxed italic border-l-2 border-[#444444] pl-4 py-1">
                            {selectedProject.problemStatement || 'No objective defined.'}
                         </p>
                      </div>

                      <div>
                         <h4 className="text-[9px] font-black text-[#444444] uppercase tracking-[0.3em] mb-4">Activity Log</h4>
                         <div className="space-y-4">
                            {selectedProject.updates && selectedProject.updates.length > 0 ? selectedProject.updates.map((update: any) => (
                               <div key={update.id} className="p-4 bg-[#444444]/5 border border-[#444444] rounded">
                                  <div className="flex justify-between text-[10px] font-black text-[#888888] uppercase mb-1">
                                     <span>@{update.user?.name}</span>
                                     <span>{new Date(update.createdAt).toLocaleDateString()}</span>
                                  </div>
                                  <p className="text-xs text-[#E0E0E0]">{update.title}</p>
                               </div>
                            )) : <p className="text-[9px] text-[#444444] uppercase tracking-widest">No Logs</p>}
                         </div>
                      </div>
                   </div>

                   <div className="space-y-8">
                      <div>
                         <h4 className="text-[9px] font-black text-[#444444] uppercase tracking-[0.3em] mb-4">Lead Captain</h4>
                         <div className="p-4 border border-[#444444] rounded flex items-center gap-3">
                            <div className="h-8 w-8 bg-[#444444]/20 border border-[#444444] rounded flex items-center justify-center font-bold text-xs">
                               {selectedProject.assignedCaptain?.name?.[0] || '?'}
                            </div>
                            <span className="text-xs font-black text-[#E0E0E0] uppercase tracking-tighter truncate">{selectedProject.assignedCaptain?.name || 'Unassigned'}</span>
                         </div>
                      </div>

                      <div>
                         <h4 className="text-[9px] font-black text-[#444444] uppercase tracking-[0.3em] mb-4">Deployment</h4>
                         <div className="grid grid-cols-2 lg:grid-cols-1 gap-2">
                            {selectedProject.members?.map((member: any) => (
                               <div key={member.id} className="flex items-center gap-3 p-2 bg-[#444444]/5 rounded truncate">
                                  <span className="text-[10px] font-bold text-[#B0B0B0] truncate">{member.user?.name}</span>
                               </div>
                            ))}
                         </div>
                      </div>
                   </div>
                </div>
              </motion.div>
            </div>
          )}

          {(showCreate || showEdit) && (
             <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-black/60 backdrop-blur-sm">
                <motion.div 
                   initial={{ opacity: 0, y: 10 }}
                   animate={{ opacity: 1, y: 0 }}
                   className="w-full max-w-xl bg-[#121212] border border-[#444444] rounded-lg p-6 md:p-8 shadow-2xl overflow-y-auto max-h-[90vh]"
                >
                   <h3 className="text-xl md:text-2xl font-black text-[#E0E0E0] uppercase tracking-tighter mb-6">
                      {showCreate ? 'Initiate Project' : 'Modify Parameters'}
                   </h3>
                   <form onSubmit={showCreate ? handleCreate : handleUpdate} className="space-y-6">
                      <div className="space-y-2">
                        <label className="text-[9px] font-black text-[#444444] uppercase tracking-widest">Project Name</label>
                        <input 
                          type="text" required
                          className="w-full bg-transparent border border-[#444444] rounded px-4 py-3 text-xs focus:border-[#888888] outline-none text-[#E0E0E0]"
                          value={formData.projectName}
                          onChange={e => setFormData({...formData, projectName: e.target.value})}
                        />
                      </div>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="space-y-2">
                          <label className="text-[9px] font-black text-[#444444] uppercase tracking-widest">Status</label>
                          <select 
                            className="w-full bg-[#121212] border border-[#444444] rounded px-4 py-3 text-xs outline-none text-[#E0E0E0]"
                            value={formData.status}
                            onChange={e => setFormData({...formData, status: e.target.value})}
                          >
                            <option value="NOT_STARTED">NOT STARTED</option>
                            <option value="ONGOING">ONGOING</option>
                            <option value="COMPLETED">COMPLETED</option>
                          </select>
                        </div>
                        <div className="space-y-2">
                          <label className="text-[9px] font-black text-[#444444] uppercase tracking-widest">Lead Captain</label>
                          <select 
                            className="w-full bg-[#121212] border border-[#444444] rounded px-4 py-3 text-xs outline-none text-[#E0E0E0]"
                            value={formData.assignedCaptainId}
                            onChange={e => setFormData({...formData, assignedCaptainId: e.target.value})}
                          >
                            <option value="">Unassigned</option>
                            {users.map((u: any) => <option key={u.id} value={u.id}>{u.name}</option>)}
                          </select>
                        </div>
                      </div>
                      <div className="space-y-2">
                        <label className="text-[9px] font-black text-[#444444] uppercase tracking-widest">Problem Statement</label>
                        <textarea 
                           className="w-full bg-transparent border border-[#444444] rounded px-4 py-3 text-xs focus:border-[#888888] outline-none text-[#E0E0E0] min-h-[100px] resize-none"
                           value={formData.problemStatement}
                           onChange={e => setFormData({...formData, problemStatement: e.target.value})}
                        />
                      </div>
                      <div className="flex flex-col sm:flex-row gap-4 pt-6 border-t border-[#444444]">
                        <button type="button" onClick={() => { setShowCreate(false); setShowEdit(false); }} className="order-2 sm:order-1 flex-1 py-3 text-[10px] font-black uppercase text-[#888888] hover:text-[#E0E0E0]">Abort</button>
                        <button type="submit" className="order-1 sm:order-2 flex-1 py-3 bg-[#E0E0E0] text-[#121212] text-[10px] font-black uppercase tracking-widest rounded transition-all active:scale-95">Synchronize</button>
                      </div>
                   </form>
                </motion.div>
             </div>
          )}

          {showDelete && (
             <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-black/60 backdrop-blur-sm">
                <motion.div initial={{ scale: 0.95 }} animate={{ scale: 1 }} className="bg-[#121212] border border-[#444444] rounded-lg p-8 md:p-10 text-center max-w-sm w-full shadow-2xl">
                   <Trash2 size={32} className="text-red-500 mx-auto mb-6" />
                   <h3 className="text-xl font-black text-[#E0E0E0] uppercase tracking-tighter mb-2">Purge Initiative?</h3>
                   <p className="text-[10px] text-[#B0B0B0] uppercase leading-relaxed mb-8">This action will permanently erase the project from the mainframe.</p>
                   <div className="flex gap-4">
                      <button onClick={() => setShowDelete(false)} className="flex-1 py-3 text-[10px] font-black uppercase text-[#888888] hover:text-[#E0E0E0]">Abort</button>
                      <button onClick={handleDelete} className="flex-1 py-3 bg-red-600 text-white text-[10px] font-black uppercase rounded transition-all active:scale-95">Purge</button>
                   </div>
                </motion.div>
             </div>
          )}
        </AnimatePresence>

        {!loading && projects.length === 0 && (
          <div className="p-32 text-center border border-dashed border-[#444444] rounded-lg">
            <p className="text-[10px] font-black text-[#444444] uppercase tracking-[0.5em]">Tactical Silence</p>
          </div>
        )}
      </main>
    </div>
  );
}
