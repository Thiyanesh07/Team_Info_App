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
    <div className="flex flex-col lg:flex-row min-h-screen bg-[#131313] text-[#FFFFFF]">
      <Sidebar />
      
      <main className="flex-1 p-6 md:p-10 mt-16 lg:mt-0 custom-scrollbar no-scrollbar">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-[#4B4A48] pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl md:text-5xl font-black tracking-tighter text-[#FFFFFF] uppercase italic">Project Oversight</h2>
            <p className="text-[#A4A4A4] mt-1 text-[10px] md:text-xs font-black uppercase tracking-[0.2em] opacity-60">Global monitoring and regulation.</p>
          </motion.div>
          <div className="flex gap-3 w-full md:w-auto">
            <button 
              onClick={handleExportProjects}
              className="flex-1 md:flex-none px-6 py-2.5 bg-transparent border border-[#4B4A48] rounded flex items-center justify-center gap-2 hover:bg-[#EFD395]/10 transition-all font-black text-[10px] uppercase tracking-widest text-[#A4A4A4] hover:text-[#EFD395]"
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
              className="flex-1 md:flex-none px-6 py-2.5 bg-[#EFD395] text-[#131313] rounded flex items-center justify-center gap-2 hover:bg-white transition-all font-black text-[10px] uppercase tracking-widest shadow-lg active:scale-95"
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
              className="bg-[#262625] border border-[#4B4A48] rounded p-8 hover:border-[#EFD395]/30 transition-all group flex flex-col h-full relative"
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
                  className="p-2 bg-[#131313] border border-[#4B4A48] rounded text-[#777674] hover:text-[#EFD395] transition-all"
                >
                  <Edit3 size={14} />
                </button>
                <button 
                  onClick={(e) => { 
                    e.stopPropagation(); 
                    setSelectedProject(project); 
                    setShowDelete(true); 
                  }}
                  className="p-2 bg-[#131313] border border-[#4B4A48] rounded text-[#777674] hover:text-red-500 transition-all"
                >
                  <Trash2 size={14} />
                </button>
              </div>

              <div className="flex justify-between items-start mb-6">
                <div className="p-2 border border-[#4B4A48] rounded text-[#EFD395] bg-[#131313]">
                  <Rocket size={20} />
                </div>
                <div className="px-3 py-1 rounded text-[8px] font-black uppercase tracking-[0.2em] border border-[#4B4A48] text-[#777674] bg-[#131313]">
                  {project.status.replace('_', ' ')}
                </div>
              </div>

              <h3 className="text-xl font-black text-white mb-2 uppercase tracking-tight italic">
                {project.projectName || project.title}
              </h3>
              <p className="text-xs text-[#A4A4A4] line-clamp-2 mb-8 flex-1 italic opacity-60">
                {project.problemStatement || project.description || 'No briefing documented.'}
              </p>

              <div className="pt-6 border-t border-[#4B4A48] space-y-3">
                 <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest text-[#777674]">
                   <span>Lead</span>
                   <span className="text-[#FFFFFF]">{project.assignedCaptain?.name || '---'}</span>
                 </div>
                 <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest text-[#777674]">
                   <span>Deployment</span>
                   <span className="text-[#EFD395]">{project.members?.length || 0} Agents</span>
                 </div>
              </div>

              <button 
                onClick={() => openDetails(project.id)}
                className="w-full mt-6 py-3 bg-[#131313] border border-[#4B4A48] rounded text-[9px] font-black uppercase tracking-[0.2em] text-[#A4A4A4] hover:text-[#FFFFFF] hover:border-[#EFD395]/40 transition-all active:scale-95"
              >
                Records
              </button>
            </motion.div>
          ))}
        </div>

        <AnimatePresence>
          {showDetails && selectedProject && (
            <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-black/80 backdrop-blur-md">
              <motion.div 
                initial={{ opacity: 0, scale: 0.98 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.98 }}
                className="bg-[#262625] border border-[#4B4A48] rounded w-full max-w-4xl max-h-[90vh] overflow-hidden shadow-2xl flex flex-col"
              >
                <div className="p-8 md:p-10 border-b border-[#4B4A48] flex justify-between items-start bg-[#131313]/30">
                   <div className="flex gap-4 items-center">
                      <Target size={24} className="text-[#EFD395]" />
                      <div className="overflow-hidden">
                         <p className="text-[10px] font-black text-[#EFD395] uppercase tracking-[0.3em] italic">{selectedProject.status}</p>
                         <h2 className="text-lg md:text-3xl font-black text-[#FFFFFF] uppercase tracking-tighter truncate italic">{selectedProject.projectName}</h2>
                      </div>
                   </div>
                   <button onClick={() => setShowDetails(false)} className="p-2 text-[#777674] hover:text-[#FFFFFF] flex-shrink-0 transition-colors">
                      <X size={24} />
                   </button>
                </div>

                <div className="flex-1 overflow-y-auto p-6 md:p-10 space-y-8 lg:space-y-0 lg:grid lg:grid-cols-3 lg:gap-10 custom-scrollbar no-scrollbar text-[#FFFFFF]">
                   <div className="lg:col-span-2 space-y-10">
                      <div>
                         <h4 className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.3em] mb-4 flex items-center gap-2">
                           <Info size={14} /> Mission Briefing
                         </h4>
                         <p className="text-[#A4A4A4] text-sm leading-relaxed italic border-l-2 border-[#EFD395] pl-6 py-2 bg-[#131313]/20 rounded-r">
                            {selectedProject.problemStatement || 'No objective defined.'}
                         </p>
                      </div>

                      <div>
                         <h4 className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.3em] mb-6 flex items-center gap-2">
                           <Activity size={14} /> Activity Log
                         </h4>
                         <div className="space-y-4">
                            {selectedProject.updates && selectedProject.updates.length > 0 ? selectedProject.updates.map((update: any) => (
                               <div key={update.id} className="p-5 bg-[#131313] border border-[#4B4A48] rounded group hover:border-[#EFD395]/30 transition-all">
                                  <div className="flex justify-between text-[9px] font-black text-[#777674] uppercase mb-2 tracking-widest">
                                     <span className="text-[#EFD395]">@{update.user?.name}</span>
                                     <span>{new Date(update.createdAt).toLocaleDateString()}</span>
                                  </div>
                                  <p className="text-xs text-[#FFFFFF] italic font-semibold leading-relaxed pr-4">{update.title}</p>
                               </div>
                            )) : <p className="text-[10px] text-[#4B4A48] uppercase tracking-[0.3em] font-black text-center py-10">No Logs Detected</p>}
                         </div>
                      </div>
                   </div>

                   <div className="space-y-10">
                      <div>
                         <h4 className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.3em] mb-4">Lead Captain</h4>
                         <div className="p-4 bg-[#131313] border border-[#4B4A48] rounded flex items-center gap-4">
                            <div className="h-10 w-10 bg-[#262625] border border-[#4B4A48] rounded flex items-center justify-center font-black text-xs text-[#EFD395]">
                               {selectedProject.assignedCaptain?.name?.[0] || '?'}
                            </div>
                            <span className="text-xs font-black text-[#FFFFFF] uppercase tracking-tighter truncate italic">{selectedProject.assignedCaptain?.name || 'Unassigned'}</span>
                         </div>
                      </div>

                      <div>
                         <h4 className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.3em] mb-4">Deployment</h4>
                         <div className="grid grid-cols-2 lg:grid-cols-1 gap-2">
                            {selectedProject.members?.map((member: any) => (
                               <div key={member.id} className="flex items-center justify-between p-3 bg-[#131313] border border-[#4B4A48] rounded truncate group hover:border-[#EFD395]/20 transition-all">
                                  <div className="flex items-center gap-3 overflow-hidden">
                                     <div className="h-1.5 w-1.5 rounded-full bg-[#EFD395]/50 group-hover:bg-[#EFD395]" />
                                     <span className="text-[10px] font-black text-[#A4A4A4] uppercase truncate tracking-widest">{member.user?.name}</span>
                                  </div>
                                  <Shield size={10} className="text-[#4B4A48] group-hover:text-[#EFD395]/40 transition-colors" />
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
             <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-black/80 backdrop-blur-md">
                <motion.div 
                   initial={{ opacity: 0, scale: 0.95 }}
                   animate={{ opacity: 1, scale: 1 }}
                   className="w-full max-w-xl bg-[#262625] border border-[#4B4A48] rounded p-8 md:p-10 shadow-2xl overflow-y-auto max-h-[90vh] custom-scrollbar no-scrollbar"
                >
                   <h3 className="text-xl md:text-3xl font-black text-white uppercase tracking-tighter mb-10 italic">
                      {showCreate ? 'Initiate Project' : 'Modify Parameters'}
                   </h3>
                   <form onSubmit={showCreate ? handleCreate : handleUpdate} className="space-y-8">
                      <div className="space-y-3">
                        <label className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] ml-1">Project Name</label>
                        <input 
                          type="text" required
                          className="w-full bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 text-xs focus:border-[#EFD395] outline-none text-white transition-all shadow-inner font-black uppercase italic"
                          value={formData.projectName}
                          onChange={e => setFormData({...formData, projectName: e.target.value})}
                        />
                      </div>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                        <div className="space-y-3">
                          <label className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] ml-1">Status</label>
                          <select 
                            className="w-full bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 text-xs outline-none text-white transition-all shadow-inner appearance-none font-black italic"
                            value={formData.status}
                            onChange={e => setFormData({...formData, status: e.target.value})}
                          >
                            <option value="NOT_STARTED">NOT STARTED</option>
                            <option value="ONGOING">ONGOING</option>
                            <option value="COMPLETED">COMPLETED</option>
                          </select>
                        </div>
                        <div className="space-y-3">
                          <label className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] ml-1">Lead Captain</label>
                          <select 
                            className="w-full bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 text-xs outline-none text-white transition-all shadow-inner appearance-none font-black italic"
                            value={formData.assignedCaptainId}
                            onChange={e => setFormData({...formData, assignedCaptainId: e.target.value})}
                          >
                            <option value="">Unassigned</option>
                            {users.map((u: any) => <option key={u.id} value={u.id}>{u.name}</option>)}
                          </select>
                        </div>
                      </div>
                      <div className="space-y-3">
                        <label className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] ml-1">Problem Statement</label>
                        <textarea 
                           className="w-full bg-[#131313] border border-[#4B4A48] rounded px-5 py-4 text-xs focus:border-[#EFD395] outline-none text-white min-h-[140px] resize-none transition-all shadow-inner italic"
                           value={formData.problemStatement}
                           onChange={e => setFormData({...formData, problemStatement: e.target.value})}
                        />
                      </div>
                      <div className="flex flex-col sm:flex-row gap-4 pt-8 border-t border-[#4B4A48]">
                        <button type="button" onClick={() => { setShowCreate(false); setShowEdit(false); }} className="order-2 sm:order-1 flex-1 py-4 text-[10px] font-black uppercase tracking-[0.3em] text-[#777674] hover:text-red-500 transition-colors">Abort</button>
                        <button type="submit" className="order-1 sm:order-2 flex-1 py-4 bg-[#EFD395] text-[#131313] text-[10px] font-black uppercase tracking-[0.3em] rounded transition-all active:scale-95 shadow-xl">Synchronize</button>
                      </div>
                   </form>
                </motion.div>
             </div>
          )}

          {showDelete && (
             <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-black/90 backdrop-blur-xl">
                <motion.div initial={{ scale: 0.95 }} animate={{ scale: 1 }} className="bg-[#262625] border border-red-500/20 rounded-2xl p-10 text-center max-w-sm w-full shadow-2xl">
                   <div className="h-20 w-20 bg-red-500/10 border border-red-500/20 rounded flex items-center justify-center mx-auto mb-8 shadow-inner shadow-red-500/5">
                      <Trash2 size={32} className="text-red-500" />
                   </div>
                   <h3 className="text-2xl font-black text-white uppercase tracking-tighter mb-4 italic">Purge Initiative?</h3>
                   <p className="text-[10px] text-[#A4A4A4] font-black uppercase tracking-[0.3em] leading-relaxed mb-10 italic opacity-60">This action will permanently erase the project from the tactical mainframe. Recovery is not possible.</p>
                   <div className="flex gap-4">
                      <button onClick={() => setShowDelete(false)} className="flex-1 py-4 text-[10px] font-black uppercase tracking-[0.2em] text-[#777674] hover:text-white transition-all">Abort</button>
                      <button onClick={handleDelete} className="flex-1 py-4 bg-red-600 text-white text-[10px] font-black uppercase tracking-[0.2em] rounded transition-all shadow-lg active:scale-95">Purge</button>
                   </div>
                </motion.div>
             </div>
          )}
        </AnimatePresence>

        {!loading && projects.length === 0 && (
          <div className="p-32 text-center border border-dashed border-[#4B4A48] rounded">
            <p className="text-[10px] font-black text-[#777674] uppercase tracking-[0.5em] italic">Tactical Silence</p>
          </div>
        )}
      </main>
    </div>
  );
}
