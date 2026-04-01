'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api, { downloadExcel } from '@/lib/api';
import { Rocket, Target, Users, Calendar, MoreVertical, ExternalLink, Shield, X, Clock, Activity, Hexagon, Edit3, Trash2, FileSpreadsheet } from 'lucide-react';
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
      toast.info('Generating Project Report...');
      await downloadExcel('/export/projects', `Team_Projects_${new Date().getTime()}.xlsx`, { scope: 'TEAM' });
      toast.success('Project Report Downloaded');
    } catch (err: any) {
      toast.error('Export Failed', { description: 'Failed to generate projects report.' });
    }
  };

  const openDetails = async (projectId: string) => {
    // Handle Mock Data for Demo purposes
    const mock = mockProjects.find(p => p.id === projectId);
    if (mock && projects.length === 0) {
      setSelectedProject(mock);
      setShowDetails(true);
      return;
    }

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
      if (['1', '2', '3'].includes(selectedProject?.id)) {
        alert("Cannot modify demonstration data.");
        return;
      }
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
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to update project');
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
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to create project');
    }
  };

  const handleDelete = async () => {
    try {
      if (['1', '2', '3'].includes(selectedProject?.id)) {
        alert("Cannot delete demonstration data.");
        return;
      }
      const res = await api.delete(`/admin/manage/projects/${selectedProject.id}`);
      if (res.data.success) {
        setShowDelete(false);
        fetchProjects();
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to delete project');
    }
  };

  // Temporary mock data until the admin/projects endpoint is verified
  const mockProjects = [
    { 
      id: '1', 
      projectName: 'Command Center Redesign', 
      status: 'ONGOING', 
      assignedCaptain: { name: 'Thiyanesh' }, 
      members: [
        { id: 'm1', user: { name: 'Thiyanesh', role: 'ADMIN' } },
        { id: 'm2', user: { name: 'Sarah', role: 'MEMBER' } }
      ], 
      problemStatement: 'Revamping the administrative oversight tool with Next.js to achieve full feature parity with the mobile Command Center.',
      domain: 'Web Architecture',
      subDomain: 'Administrative Dashboard',
      updates: [
        { id: 'u1', title: 'Dashboard UI Revamp', user: { name: 'Thiyanesh' }, createdAt: new Date() },
        { id: 'u2', title: 'Authentication Logic Sync', user: { name: 'Thiyanesh' }, createdAt: new Date(Date.now() - 86400000) }
      ]
    },
    { 
      id: '2', 
      projectName: 'Neural Core Alpha', 
      status: 'COMPLETED', 
      assignedCaptain: { name: 'Alex' }, 
      members: [
        { id: 'm3', user: { name: 'Alex', role: 'CAPTAIN' } },
        { id: 'm4', user: { name: 'Chen', role: 'MEMBER' } }
      ], 
      problemStatement: 'High-performance AI inference engine for student projects utilizing local LLM quantization.',
      domain: 'Artificial Intelligence',
      subDomain: 'Model Deployment',
      updates: []
    },
    { 
      id: '3', 
      projectName: 'Project Zenith', 
      status: 'NOT_STARTED', 
      assignedCaptain: { name: 'Liam' }, 
      members: [
        { id: 'm5', user: { name: 'Liam', role: 'STRATEGIST' } }
      ], 
      problemStatement: 'Upcoming research on decentralized team management and operational sovereignty.',
      domain: 'Systems Design',
      subDomain: 'Decentralization',
      updates: []
    },
  ];

  const displayProjects = projects.length > 0 ? projects : mockProjects;

  return (
    <div className="flex min-h-screen bg-slate-950 text-slate-50">
      <Sidebar />
      
      <main className="flex-1 p-8">
        <header className="mb-10 flex justify-between items-end">
          <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl font-black tracking-tight text-white uppercase">Project Oversight</h2>
            <p className="text-slate-400 mt-1 font-medium italic">Global monitoring and regulation of team-led initiatives.</p>
          </motion.div>
          <div className="flex gap-4 items-center">
            <button 
              onClick={handleExportProjects}
              className="px-6 py-3 bg-slate-900 border border-slate-700 hover:border-emerald-500/50 hover:bg-emerald-500/5 text-slate-300 hover:text-emerald-400 rounded-2xl text-[10px] font-black uppercase tracking-widest transition-all shadow-xl active:scale-95 group flex items-center gap-2"
            >
              <FileSpreadsheet size={16} className="group-hover:animate-pulse" />
              Export Projects
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
              className="px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-2xl text-xs font-black uppercase tracking-widest text-white shadow-lg shadow-blue-600/20 active:scale-95 transition-all"
            >
              New Initiative +
            </button>
            <div className="px-4 py-3 bg-slate-900 border border-slate-800 rounded-2xl flex items-center gap-3">
              <div className="h-2 w-2 rounded-full bg-blue-500 animate-pulse" />
              <span className="text-[10px] font-black text-slate-300 uppercase tracking-widest">Tracking {displayProjects.length} Units</span>
            </div>
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {displayProjects.map((project, i) => (
            <motion.div 
              key={project.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className="bg-slate-900 border border-slate-800 rounded-[2.5rem] p-8 hover:border-blue-500/30 transition-all group flex flex-col h-full relative overflow-hidden"
            >
              <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:opacity-10 transition-opacity">
                 <Rocket size={80} />
              </div>
              
              <div className="absolute top-6 right-6 flex gap-2 z-20 opacity-0 group-hover:opacity-100 transition-opacity translate-x-4 group-hover:translate-x-0">
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
                  className="p-3 bg-slate-950/80 backdrop-blur-md border border-slate-700/50 rounded-xl text-slate-400 hover:text-blue-400 hover:border-blue-500 hover:shadow-lg hover:shadow-blue-500/10 transition-all active:scale-95"
                  title="Modify Parameter"
                >
                  <Edit3 size={16} />
                </button>
                <button 
                  onClick={(e) => { 
                    e.stopPropagation(); 
                    setSelectedProject(project); 
                    setShowDelete(true); 
                  }}
                  className="p-3 bg-slate-950/80 backdrop-blur-md border border-slate-700/50 rounded-xl text-slate-400 hover:text-rose-400 hover:border-rose-500 hover:shadow-lg hover:shadow-rose-500/10 transition-all active:scale-95"
                  title="Terminate Project"
                >
                  <Trash2 size={16} />
                </button>
              </div>

              <div className="flex justify-between items-start mb-6">
                <div className={cn(
                  "p-4 rounded-[1.25rem] border shadow-lg",
                  project.status === 'COMPLETED' ? "bg-emerald-500/10 border-emerald-500/20 text-emerald-500" :
                  project.status === 'ONGOING' ? "bg-blue-500/10 border-blue-500/20 text-blue-500" :
                  "bg-slate-500/10 border-slate-500/20 text-slate-400"
                )}>
                  <Rocket size={24} />
                </div>
                <div className={cn(
                  "px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-[0.2em] border backdrop-blur-md",
                  project.status === 'COMPLETED' ? "bg-emerald-500/10 text-emerald-500 border-emerald-500/20" :
                  project.status === 'ONGOING' ? "bg-blue-500/10 text-blue-500 border-blue-500/20" :
                  "bg-slate-500/10 text-slate-400 border-slate-700"
                )}>
                  {project.status.replace('_', ' ')}
                </div>
              </div>

              <h3 className="text-2xl font-black text-white mb-3 group-hover:text-blue-400 transition-colors uppercase tracking-tight leading-none">
                {project.projectName || project.title}
              </h3>
              <p className="text-sm text-slate-500 line-clamp-2 mb-8 flex-1 italic leading-relaxed font-medium">
                "{project.problemStatement || project.description || 'No mission objective defined.'}"
              </p>

              <div className="pt-8 border-t border-slate-800/50 space-y-5">
                <div className="flex items-center justify-between">
                  <span className="text-[10px] text-slate-500 flex items-center gap-2 font-black uppercase tracking-widest">
                    <Shield size={14} className="text-blue-500" /> Lead Captain
                  </span>
                  <span className="text-sm text-slate-200 font-bold">{project.assignedCaptain?.name || 'Unassigned'}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-[10px] text-slate-500 flex items-center gap-2 font-black uppercase tracking-widest">
                    <Users size={14} className="text-slate-400" /> Deployment
                  </span>
                  <div className="flex items-center gap-1.5">
                    <span className="text-sm text-white font-black">{project.members?.length || 0}</span>
                    <span className="text-[10px] text-slate-600 font-black uppercase tracking-tighter">Active Agents</span>
                  </div>
                </div>
              </div>

              <button 
                onClick={() => openDetails(project.id)}
                className="w-full mt-8 py-4 bg-slate-950 border border-slate-800 rounded-2xl text-[10px] font-black uppercase tracking-[0.3em] text-slate-400 hover:bg-blue-600 hover:text-white hover:border-blue-500 transition-all flex items-center justify-center gap-3 shadow-xl active:scale-95"
              >
                Detailed Records <ExternalLink size={14} />
              </button>
            </motion.div>
          ))}
        </div>

        <AnimatePresence>
          {showDetails && selectedProject && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-xl">
              <motion.div 
                initial={{ opacity: 0, scale: 0.9, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.9, y: 20 }}
                className="bg-slate-900 border border-slate-800 rounded-[3rem] w-full max-w-4xl max-h-[90vh] overflow-hidden shadow-2xl flex flex-col"
              >
                {/* Modal Header */}
                <div className="p-10 pb-6 border-b border-slate-800 flex justify-between items-start bg-slate-900/50">
                   <div className="flex gap-6 items-center">
                      <div className="h-16 w-16 bg-blue-600/10 border border-blue-500/20 rounded-2xl flex items-center justify-center text-blue-500 shadow-lg shadow-blue-600/10">
                         <Target size={32} />
                      </div>
                      <div>
                         <div className="flex items-center gap-3 mb-1">
                            <span className="px-3 py-0.5 rounded-md bg-slate-800 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] border border-slate-700">Project Core</span>
                            <span className="text-xs font-black text-emerald-500 uppercase tracking-widest">{selectedProject.status}</span>
                         </div>
                         <h2 className="text-3xl font-black text-white uppercase tracking-tighter">{selectedProject.projectName}</h2>
                      </div>
                   </div>
                   <button onClick={() => setShowDetails(false)} className="p-3 bg-slate-950 border border-slate-800 rounded-2xl text-slate-500 hover:text-white hover:bg-slate-800 transition-colors">
                      <X size={24} />
                   </button>
                </div>

                {/* Modal Content */}
                <div className="flex-1 overflow-y-auto p-10 grid grid-cols-1 lg:grid-cols-3 gap-10">
                   <div className="lg:col-span-2 space-y-10">
                      <div>
                         <h4 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.3em] mb-4 flex items-center gap-2">
                            <Activity size={12} className="text-blue-500" /> Mission Briefing
                         </h4>
                         <p className="text-slate-300 leading-relaxed font-medium bg-slate-950/50 border border-slate-800/50 p-6 rounded-3xl italic">
                            "{selectedProject.problemStatement || 'No briefing documented for this operation.'}"
                         </p>
                      </div>

                      <div className="grid grid-cols-2 gap-6">
                         <div className="p-6 bg-slate-950/30 border border-slate-800 rounded-3xl">
                            <p className="text-[10px] font-black text-slate-600 uppercase tracking-widest mb-2">Primary Domain</p>
                            <p className="text-sm font-bold text-white uppercase">{selectedProject.domain || 'Unclassified'}</p>
                         </div>
                         <div className="p-6 bg-slate-950/30 border border-slate-800 rounded-3xl">
                            <p className="text-[10px] font-black text-slate-600 uppercase tracking-widest mb-2">Technical Sector</p>
                            <p className="text-sm font-bold text-white uppercase">{selectedProject.subDomain || 'N/A'}</p>
                         </div>
                      </div>

                      <div>
                         <h4 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.3em] mb-4 flex items-center gap-2">
                            <Clock size={12} className="text-amber-500" /> Operational Feed
                         </h4>
                         <div className="space-y-4">
                            {selectedProject.updates && selectedProject.updates.length > 0 ? selectedProject.updates.map((update: any) => (
                               <div key={update.id} className="p-6 bg-slate-950/50 border border-slate-800 rounded-3xl space-y-2">
                                  <div className="flex justify-between items-center">
                                     <span className="text-xs font-black text-blue-400 uppercase tracking-tighter">@{update.user?.name}</span>
                                     <span className="text-[10px] font-bold text-slate-600">{new Date(update.createdAt).toLocaleDateString()}</span>
                                  </div>
                                  <p className="text-sm text-slate-300 leading-relaxed font-medium">{update.title}</p>
                               </div>
                            )) : (
                               <div className="flex items-center gap-3 p-6 text-slate-500 italic text-sm border border-dashed border-slate-800 rounded-3xl">
                                  <Info size={16} /> No updates reported for this sector.
                               </div>
                            )}
                         </div>
                      </div>
                   </div>

                   <div className="space-y-10">
                      <div>
                         <h4 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.3em] mb-4 flex items-center gap-2">
                            <Shield size={12} className="text-blue-500" /> Command Unit
                         </h4>
                         <div className="p-5 bg-slate-950/50 border border-slate-800 rounded-3xl flex items-center gap-4">
                            <div className="h-10 w-10 bg-slate-800 rounded-xl flex items-center justify-center font-bold text-blue-400 border border-slate-700">
                               {selectedProject.assignedCaptain?.name?.[0] || 'U'}
                            </div>
                            <div>
                               <p className="text-sm font-bold text-white">{selectedProject.assignedCaptain?.name || 'Unassigned'}</p>
                               <p className="text-[10px] font-black text-slate-600 uppercase tracking-widest">Lead Captain</p>
                            </div>
                         </div>
                      </div>

                      <div>
                         <h4 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.3em] mb-4 flex items-center gap-2">
                            <Users size={12} className="text-slate-500" /> Team Roster
                         </h4>
                         <div className="space-y-3">
                            {selectedProject.members?.map((member: any) => (
                               <div key={member.id} className="flex items-center gap-3 p-3 bg-slate-950/30 border border-slate-800/50 rounded-2xl group hover:border-slate-700 transition-colors">
                                  <div className="h-8 w-8 bg-slate-900 border border-slate-800 rounded-lg flex items-center justify-center text-[10px] font-black text-slate-500 uppercase">
                                     {member.user?.name?.[0] || 'A'}
                                  </div>
                                  <div className="flex-1 min-w-0">
                                     <p className="text-[11px] font-bold text-slate-200 truncate">{member.user?.name}</p>
                                     <p className="text-[9px] font-black text-slate-600 uppercase tracking-tighter">{member.user?.role || 'Agent'}</p>
                                  </div>
                                  <Hexagon size={12} className="text-slate-800 group-hover:text-blue-500/50 transition-colors" />
                               </div>
                            ))}
                         </div>
                      </div>
                   </div>
                </div>

                <div className="p-6 bg-slate-950/50 border-t border-slate-800 text-center">
                   <p className="text-[10px] font-black text-slate-700 uppercase tracking-[0.5em]">Synchronized at {new Date().toLocaleTimeString()}</p>
                </div>
              </motion.div>
            </div>
          )}

          {showCreate && (
             <div className="fixed inset-0 z-[60] flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-xl">
                <motion.div 
                   initial={{ opacity: 0, scale: 0.9, y: 20 }}
                   animate={{ opacity: 1, scale: 1, y: 0 }}
                   exit={{ opacity: 0, scale: 0.9, y: 20 }}
                   className="relative w-full max-w-xl bg-slate-900 border border-slate-700/50 rounded-[2.5rem] shadow-2xl overflow-hidden"
                >
                   <div className="p-8 pb-0 flex justify-between items-start">
                      <div>
                         <h3 className="text-2xl font-black text-white uppercase tracking-tighter">Initiate Project</h3>
                         <p className="text-slate-400 text-sm mt-1">Define new operational objective and deployment.</p>
                      </div>
                      <button onClick={() => setShowCreate(false)} className="p-2 hover:bg-slate-800 rounded-full text-slate-500 transition-colors">
                         <X size={20} />
                      </button>
                   </div>
                   <form onSubmit={handleCreate} className="p-8 pb-10">
                      <ProjectForm formData={formData} setFormData={setFormData} users={users} />
                      <div className="flex gap-4 pt-8 border-t border-slate-800 mt-6">
                         <button 
                            type="button" onClick={() => setShowCreate(false)}
                            className="flex-1 px-6 py-4 bg-slate-800 hover:bg-slate-750 text-white rounded-2xl font-bold transition-all active:scale-95"
                         >
                            Abort
                         </button>
                         <button 
                            type="submit"
                            className="flex-1 px-6 py-4 bg-blue-600 hover:bg-blue-500 text-white rounded-2xl font-bold transition-all shadow-lg shadow-blue-600/20 active:scale-95"
                         >
                            Execute Launch
                         </button>
                      </div>
                   </form>
                </motion.div>
             </div>
          )}

          {showEdit && selectedProject && (
            <div className="fixed inset-0 z-[60] flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-xl">
              <motion.div 
                initial={{ opacity: 0, scale: 0.9, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.9, y: 20 }}
                className="relative w-full max-w-xl bg-slate-900 border border-slate-700/50 rounded-[2.5rem] shadow-2xl overflow-hidden"
              >
                <div className="p-8 pb-0 flex justify-between items-start">
                  <div>
                    <h3 className="text-2xl font-black text-white uppercase tracking-tighter">Modify Parameters</h3>
                    <p className="text-slate-400 text-sm mt-1">Adjust operational metadata and active status.</p>
                  </div>
                  <button onClick={() => setShowEdit(false)} className="p-2 hover:bg-slate-800 rounded-full text-slate-500 transition-colors">
                    <X size={20} />
                  </button>
                </div>

                <form onSubmit={handleUpdate} className="p-8 pb-10">
                  <ProjectForm formData={formData} setFormData={setFormData} users={users} />
                  <div className="flex gap-4 pt-8 border-t border-slate-800 mt-6">
                    <button 
                      type="button" onClick={() => setShowEdit(false)}
                      className="flex-1 px-6 py-4 bg-slate-800 hover:bg-slate-750 text-white rounded-2xl font-bold transition-all active:scale-95"
                    >
                      Discard
                    </button>
                    <button 
                      type="submit"
                      className="flex-1 px-6 py-4 bg-blue-600 hover:bg-blue-500 text-white rounded-2xl font-bold transition-all shadow-lg shadow-blue-600/20 active:scale-95"
                    >
                      Sync Overrides
                    </button>
                  </div>
                </form>
              </motion.div>
            </div>
          )}

          {showDelete && selectedProject && (
            <div className="fixed inset-0 z-[60] flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-xl">
              <motion.div 
                initial={{ scale: 0.9, opacity: 0, y: 20 }}
                animate={{ scale: 1, opacity: 1, y: 0 }}
                exit={{ scale: 0.9, opacity: 0, y: 20 }}
                className="relative w-full max-w-md bg-slate-900 border border-rose-500/20 rounded-[2.5rem] shadow-2xl p-10 text-center"
              >
                <div className="h-20 w-20 bg-rose-500/10 border border-rose-500/20 rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-inner">
                  <Trash2 size={32} className="text-rose-500" />
                </div>
                <h3 className="text-2xl font-black text-white uppercase tracking-tighter">Terminate Project?</h3>
                <p className="text-slate-400 text-sm mt-3 leading-relaxed">
                  You are about to delete <strong className="text-rose-400">"{selectedProject.projectName || selectedProject.title}"</strong>. This protocol is irreversible and all embedded datasets will be purged from the core.
                </p>

                <div className="flex gap-4 mt-8">
                  <button 
                    onClick={() => setShowDelete(false)}
                    className="flex-1 px-6 py-4 bg-slate-800 hover:bg-slate-750 text-white rounded-2xl font-bold transition-all"
                  >
                    Abort
                  </button>
                  <button 
                    onClick={handleDelete}
                    className="flex-1 px-6 py-4 bg-rose-600 hover:bg-rose-500 text-white rounded-2xl font-black uppercase tracking-widest transition-all shadow-lg shadow-rose-600/20 active:scale-95"
                  >
                    Terminate
                  </button>
                </div>
              </motion.div>
            </div>
          )}
        </AnimatePresence>

        {displayProjects.length === 0 && !loading && (
          <div className="p-32 text-center text-slate-500 border-2 border-dashed border-slate-800 rounded-[3rem]">
            <Rocket size={48} className="mx-auto mb-4 opacity-10" />
            <p className="font-bold text-lg text-slate-400 uppercase tracking-widest">Tactical Silence</p>
            <p className="text-sm mt-1">No operational initiatives registered in the mainframe.</p>
          </div>
        )}
      </main>
    </div>
  );
}

function ProjectForm({ formData, setFormData, users }: any) {
  return (
    <div className="space-y-6 max-h-[60vh] overflow-y-auto px-1 pr-4">
      <div className="space-y-2">
        <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Initiative Title</label>
        <input 
          type="text" required
          className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-bold text-white shadow-inner"
          value={formData.projectName}
          onChange={e => setFormData({...formData, projectName: e.target.value})}
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Operational Status</label>
          <select 
            className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-bold text-white appearance-none shadow-inner"
            value={formData.status}
            onChange={e => setFormData({...formData, status: e.target.value})}
          >
            <option value="NOT_STARTED">NOT STARTED</option>
            <option value="IN_PROGRESS">IN PROGRESS</option>
            <option value="COMPLETED">COMPLETED</option>
            <option value="ON_HOLD">ON HOLD</option>
          </select>
        </div>

        <div className="space-y-2">
          <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Lead Captain</label>
          <select 
            className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-bold text-white appearance-none shadow-inner"
            value={formData.assignedCaptainId}
            onChange={e => setFormData({...formData, assignedCaptainId: e.target.value})}
          >
            <option value="">Unassigned</option>
            {users.map((u: any) => <option key={u.id} value={u.id}>{u.name}</option>)}
          </select>
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1 flex justify-between items-center">
          Agent Deployment
          <span className="text-[9px] text-slate-600 lowercase tracking-normal font-medium">{formData.memberIds.length} agents selected</span>
        </label>
        <div className="grid grid-cols-3 gap-2 p-4 bg-slate-950 border border-slate-800 rounded-2xl shadow-inner max-h-48 overflow-y-auto">
          {users.map((u: any) => {
            const selected = formData.memberIds.includes(u.id);
            return (
              <button
                key={u.id}
                type="button"
                onClick={() => {
                  const next = selected 
                    ? formData.memberIds.filter((id: string) => id !== u.id)
                    : [...formData.memberIds, u.id];
                  setFormData({...formData, memberIds: next});
                }}
                className={cn(
                  "px-3 py-2 rounded-xl text-[10px] font-bold border transition-all truncate text-left",
                  selected ? "bg-blue-600/10 border-blue-500 text-blue-400 shadow-lg shadow-blue-500/5" : "bg-slate-900/50 border-slate-800 text-slate-500 hover:border-slate-700"
                )}
              >
                {u.name}
              </button>
            );
          })}
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Mission Briefing</label>
        <textarea 
          className="w-full h-24 bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-medium text-slate-300 resize-none shadow-inner"
          value={formData.problemStatement}
          onChange={e => setFormData({...formData, problemStatement: e.target.value})}
        />
      </div>
    </div>
  );
}

function Info({ size }: { size: number }) {
  return (
    <svg 
      width={size} 
      height={size} 
      viewBox="0 0 24 24" 
      fill="none" 
      stroke="currentColor" 
      strokeWidth="2" 
      strokeLinecap="round" 
      strokeLinejoin="round" 
      className="lucide lucide-info"
    >
      <circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>
    </svg>
  );
}
