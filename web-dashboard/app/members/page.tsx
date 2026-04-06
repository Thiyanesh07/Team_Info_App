'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api, { downloadExcel } from '@/lib/api';
import { Users, MoreVertical, Shield, Mail, Building, Plus, Trash2, Edit3, X, Check, Search, Star, Flame, LayoutList, GraduationCap, BookOpen, Trash, Hexagon, FileSpreadsheet, ExternalLink } from 'lucide-react';
import { toast } from 'sonner';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';

export default function MembersPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState<'create' | 'edit' | 'delete' | 'portfolio' | null>(null);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [portfolioData, setPortfolioData] = useState<{skills: any[], learnings: any[], certs: any[]}>({skills: [], learnings: [], certs: []});
  const [portfolioTab, setPortfolioTab] = useState<'skills' | 'learning' | 'certs'>('skills');
  const [portfolioLoading, setPortfolioLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    role: 'MEMBER',
    regNo: '',
    enrollmentNo: '',
    department: '',
    rewardPoints: 0,
    activityPoints: 0
  });

  useEffect(() => {
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
    } finally {
      setLoading(false);
    }
  };

  const handleExportPortfolio = async (type: 'skills' | 'learning' | 'certifications') => {
    if (!selectedUser) return;
    try {
      const label = type === 'skills' ? 'Skills' : type === 'learning' ? 'Learning' : 'Certifications';
      toast.info(`Generating ${label} Report...`);
      const endpoint = `/export/${type}`;
      await downloadExcel(endpoint, `${selectedUser.name}_${label}_${new Date().getTime()}.xlsx`, { 
        scope: 'USER',
        userId: selectedUser.id 
      });
      toast.success(`${label} Report Downloaded`);
    } catch (err: any) {
      toast.error('Export Failed');
    }
  };

  const handleExportUsers = async () => {
    try {
      toast.info('Generating Team Roster...');
      // Note: We don't have a dedicated /export/users but since users are essentially the base, 
      // we can reuse another export that includes user data if applicable, or just daily logs if requested.
      // The user requested: daily log, projects, hackathons, skills, learning, certs.
      // I will assume they might want a general skills/learning matrix for all.
      await downloadExcel('/export/activities', `Team_Roster_Activities_${new Date().getTime()}.xlsx`, { scope: 'TEAM' });
      toast.success('Roster Data Downloaded');
    } catch (err: any) {
      toast.error('Export Failed');
    }
  };

  const resetForm = () => {
    setFormData({
      name: '',
      email: '',
      role: 'MEMBER',
      regNo: '',
      enrollmentNo: '',
      department: '',
      rewardPoints: 0,
      activityPoints: 0
    });
    setSelectedUser(null);
  };

  const openCreateModal = () => {
    resetForm();
    setShowModal('create');
  };

  const openEditModal = (user: any) => {
    setFormData({
      name: user.name || '',
      email: user.email || '',
      role: user.role || 'MEMBER',
      regNo: user.regNo || '',
      enrollmentNo: user.enrollmentNo || '',
      department: user.department || '',
      rewardPoints: user.rewardPoints || 0,
      activityPoints: user.activityPoints || 0
    });
    setSelectedUser(user);
    setShowModal('edit');
  };

  const openDeleteModal = (user: any) => {
    setSelectedUser(user);
    setShowModal('delete');
  };

  const openPortfolioModal = async (user: any) => {
    setSelectedUser(user);
    setShowModal('portfolio');
    setPortfolioTab('skills');
    setPortfolioLoading(true);
    try {
      const [skills, learnings, certs] = await Promise.all([
        api.get(`/ps-skills/user/${user.id}`),
        api.get(`/learning/user/${user.id}`),
        api.get(`/certifications/user/${user.id}`)
      ]);
      setPortfolioData({
        skills: skills.data.data || [],
        learnings: learnings.data.data || [],
        certs: certs.data.data || []
      });
    } catch (err) {
      console.error('Fetch portfolio error:', err);
    } finally {
      setPortfolioLoading(false);
    }
  };

  const handleDeleteSubItem = async (type: string, id: string) => {
    if (!confirm('Are you sure you want to delete this record?')) return;
    try {
      let endpoint = '';
      if (type === 'skill') endpoint = `/ps-skills/${id}`;
      else if (type === 'learning') endpoint = `/learning/${id}`;
      else if (type === 'cert') endpoint = `/certifications/${id}`;
      
      const res = await api.delete(endpoint);
      if (res.data.success) {
        // Refresh portfolio
        openPortfolioModal(selectedUser);
      }
    } catch (err: any) {
      alert('Delete failed');
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await api.post('/users/create', formData);
      if (res.data.success) {
        setShowModal(null);
        fetchUsers();
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to create member');
    }
  };

  const handleUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      // Update basic info
      const res = await api.put(`/users/${selectedUser.id}`, formData);
      
      // Update role if changed
      if (formData.role !== selectedUser.role) {
        await api.put(`/users/${selectedUser.id}/role`, { role: formData.role });
      }

      if (res.data.success) {
        setShowModal(null);
        fetchUsers();
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to update member');
    }
  };

  const handleDelete = async () => {
    try {
      const res = await api.delete(`/users/${selectedUser.id}`);
      if (res.data.success) {
        setShowModal(null);
        fetchUsers();
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to delete member');
    }
  };

  const filteredUsers = users.filter(u => 
    u.name.toLowerCase().includes(search.toLowerCase()) || 
    u.email.toLowerCase().includes(search.toLowerCase()) ||
    (u.department && u.department.toLowerCase().includes(search.toLowerCase()))
  );

  return (
    <div className="flex min-h-screen bg-[#131313] text-[#FFFFFF]">
      <Sidebar />
      
      <main className="flex-1 p-6 md:p-10 overflow-y-auto mt-16 lg:mt-0 custom-scrollbar no-scrollbar">
        <header className="flex flex-col md:flex-row justify-between items-start md:items-end mb-12 border-b border-[#4B4A48] pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl md:text-5xl font-black tracking-tighter text-[#FFFFFF] uppercase italic">Team Roster</h2>
            <p className="text-[#A4A4A4] mt-1 font-bold uppercase text-[10px] tracking-widest opacity-60">Global monitoring of operational squad units.</p>
          </motion.div>
          <div className="flex gap-4 w-full md:w-auto">
            <button 
              onClick={handleExportUsers}
              className="flex-1 md:flex-none items-center justify-center gap-2.5 px-6 py-3 bg-transparent border border-[#4B4A48] hover:border-[#EFD395]/50 hover:bg-[#EFD395]/5 text-[#A4A4A4] hover:text-[#EFD395] rounded transition-all shadow-xl active:scale-95 group text-[10px] font-black uppercase tracking-widest"
            >
              <FileSpreadsheet size={16} className="group-hover:animate-pulse" />
              Export Roster
            </button>
            <button 
              onClick={openCreateModal}
              className="flex-1 md:flex-none items-center justify-center gap-2 px-6 py-3 bg-[#EFD395] text-[#131313] hover:bg-white rounded font-black text-[10px] uppercase tracking-widest transition-all shadow-lg active:scale-95"
            >
              <Plus size={18} />
              Onboard Member
            </button>
          </div>
        </header>

        <div className="bg-[#262625] border border-[#4B4A48] rounded overflow-hidden shadow-2xl backdrop-blur-xl">
          <div className="p-6 border-b border-[#4B4A48] flex items-center gap-4 bg-[#131313]/30">
            <div className="relative flex-1">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-[#777674]" size={18} />
              <input 
                type="text" 
                placeholder="Search units by name, email or department..." 
                className="w-full bg-[#131313] border border-[#4B4A48] rounded pl-12 pr-4 py-3.5 text-sm focus:outline-none focus:border-[#EFD395] transition-all font-medium text-[#FFFFFF] italic"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
          </div>

          <div className="overflow-x-auto no-scrollbar">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-[#131313]/50 text-[#777674] text-[10px] uppercase tracking-[0.2em] font-black">
                  <th className="px-8 py-5">Identified Account</th>
                  <th className="px-8 py-5">Assigned Role</th>
                  <th className="px-8 py-5">Performance Units</th>
                  <th className="px-8 py-5 text-right">Administrative</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#4B4A48]/50">
                {filteredUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-[#4B4A48]/10 transition-colors group">
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-4">
                        <div className="h-12 w-12 rounded bg-[#131313] border border-[#4B4A48] flex items-center justify-center font-black text-[#A4A4A4] shadow-inner overflow-hidden italic text-lg">
                          {user.profileImageUrl ? (
                            <img src={user.profileImageUrl} alt="" className="w-full h-full object-cover" />
                          ) : (
                            user.name[0].toUpperCase()
                          )}
                        </div>
                        <div>
                          <div className="font-black text-[#FFFFFF] text-base uppercase tracking-tighter italic">{user.name}</div>
                          <div className="text-[10px] text-[#A4A4A4] flex items-center gap-1.5 mt-0.5 font-bold uppercase tracking-wider">
                            <Mail size={12} className="opacity-50 text-[#EFD395]" /> {user.email}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-6">
                      <span className={cn(
                        "inline-flex items-center gap-1.5 px-3 py-1 rounded text-[9px] font-black uppercase tracking-widest border transition-all",
                        user.role === 'ADMIN' ? "bg-red-500/10 text-red-400 border-red-500/20 shadow-[0_0_10px_rgba(239,68,68,0.1)]" : 
                        "bg-[#262625] text-[#A4A4A4] border-[#4B4A48]"
                      )}>
                        <Shield size={10} strokeWidth={3} className={cn(user.role === 'ADMIN' ? "text-red-400" : "text-[#EFD395]")} />
                        {user.role.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-8 py-6">
                      <div className="flex flex-col gap-2">
                        <div className="flex items-center gap-3">
                          <div className="flex items-center gap-1.5 bg-[#131313] border border-[#4B4A48] rounded px-2 py-1 group-hover:border-[#EFD395]/30 transition-all">
                            <Star size={10} className="text-[#EFD395] fill-[#EFD395]/20" />
                            <span className="text-[10px] font-black text-[#EFD395]">{user.rewardPoints} RPT</span>
                          </div>
                          <div className="flex items-center gap-1.5 bg-[#131313] border border-[#4B4A48] rounded px-2 py-1">
                            <Flame size={10} className="text-[#A4A4A4]" />
                            <span className="text-[10px] font-black text-[#A4A4A4]">{user.activityPoints} APT</span>
                          </div>
                        </div>
                        <span className="text-[9px] text-[#777674] font-black uppercase tracking-widest ml-1 leading-none">
                          {user.department || 'UNCATEGORIZED'} • {user.enrollmentNo ? `ID: ${user.enrollmentNo}` : 'NO PORTAL ID'}
                        </span>
                      </div>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <div className="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button 
                          onClick={() => openPortfolioModal(user)}
                          className="p-2.5 rounded hover:bg-[#EFD395]/10 text-[#777674] hover:text-[#EFD395] transition-all border border-transparent hover:border-[#EFD395]/20"
                          title="View Portfolio"
                        >
                          <LayoutList size={18} />
                        </button>
                        <button 
                          onClick={() => openEditModal(user)}
                          className="p-2.5 rounded hover:bg-white/10 text-[#777674] hover:text-[#FFFFFF] transition-all border border-transparent hover:border-white/20"
                          title="Edit Profile"
                        >
                          <Edit3 size={18} />
                        </button>
                        <button 
                          onClick={() => openDeleteModal(user)}
                          className="p-2.5 rounded hover:bg-red-500/10 text-[#777674] hover:text-red-400 transition-all border border-transparent hover:border-red-500/20"
                          title="Delete Account"
                        >
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          
          {filteredUsers.length === 0 && !loading && (
            <div className="p-32 text-center text-[#777674]">
              <div className="h-20 w-20 bg-[#131313] border border-[#4B4A48] rounded flex items-center justify-center mx-auto mb-6 shadow-inner">
                <Users size={32} className="opacity-20" />
              </div>
              <p className="font-black text-lg text-[#A4A4A4] uppercase tracking-tighter italic">Zero tactical matches</p>
              <p className="text-[10px] mt-1 font-bold uppercase tracking-widest">Refine your search parameters and try again.</p>
            </div>
          )}
        </div>
      </main>

      <AnimatePresence>
        {(showModal === 'create' || showModal === 'edit') && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-6 sm:p-0">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowModal(null)}
              className="absolute inset-0 bg-black/80 backdrop-blur-md"
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 20 }}
              className="relative w-full max-w-xl bg-[#262625] border border-[#4B4A48] rounded p-10 shadow-2xl overflow-hidden"
            >
              <div className="flex justify-between items-start mb-8">
                <div>
                  <h3 className="text-2xl font-black text-[#FFFFFF] uppercase tracking-tighter italic">{showModal === 'create' ? 'Onboard Member' : 'Regulate Account'}</h3>
                  <p className="text-[#A4A4A4] text-[10px] font-black uppercase tracking-widest mt-1">Configure administrative permissions and metrics.</p>
                </div>
                <button onClick={() => setShowModal(null)} className="p-2 hover:bg-[#131313] rounded text-[#777674] transition-colors">
                  <X size={20} />
                </button>
              </div>

              <form onSubmit={showModal === 'create' ? handleCreate : handleUpdate} className="space-y-6">
                <div className="grid grid-cols-2 gap-6">
                  <div className="space-y-2 col-span-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-[#777674] ml-1 leading-none">Full Identity</label>
                    <input 
                      type="text" required
                      className="w-full bg-[#131313] border border-[#4B4A48] rounded px-4 py-3.5 text-sm focus:outline-none focus:border-[#EFD395] transition-all font-black text-[#FFFFFF] italic shadow-inner"
                      placeholder="e.g. Alex Johnson"
                      value={formData.name}
                      onChange={e => setFormData({...formData, name: e.target.value})}
                    />
                  </div>
                  
                  <div className="space-y-2 col-span-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-[#777674] ml-1 leading-none">Google Email Anchor</label>
                    <input 
                      type="email" required
                      readOnly={showModal === 'edit'}
                      className={cn(
                        "w-full bg-[#131313] border border-[#4B4A48] rounded px-4 py-3.5 text-sm focus:outline-none focus:border-[#EFD395] transition-all font-black text-[#FFFFFF] italic shadow-inner",
                        showModal === 'edit' && "opacity-50 cursor-not-allowed"
                      )}
                      placeholder="alex@team.com"
                      value={formData.email}
                      onChange={e => setFormData({...formData, email: e.target.value})}
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-[#777674] ml-1 leading-none">Assigned Rank</label>
                    <select 
                      className="w-full bg-[#131313] border border-[#4B4A48] rounded px-4 py-3.5 text-sm focus:outline-none focus:border-[#EFD395] transition-all font-black text-[#FFFFFF] appearance-none shadow-inner italic"
                      value={formData.role}
                      onChange={e => setFormData({...formData, role: e.target.value})}
                    >
                      <option value="MEMBER">MEMBER</option>
                      <option value="CAPTAIN">CAPTAIN</option>
                      <option value="VICE_CAPTAIN">VICE CAPTAIN</option>
                      <option value="STRATEGIST">STRATEGIST</option>
                      <option value="MANAGER">MANAGER</option>
                      <option value="ADMIN">ADMIN</option>
                    </select>
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-[#777674] ml-1 leading-none">Department</label>
                    <input 
                      type="text"
                      className="w-full bg-[#131313] border border-[#4B4A48] rounded px-4 py-3.5 text-sm focus:outline-none focus:border-[#EFD395] transition-all font-black text-[#FFFFFF] italic shadow-inner"
                      placeholder="Engineering"
                      value={formData.department}
                      onChange={e => setFormData({...formData, department: e.target.value})}
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-[#EFD395] ml-1 leading-none">Reward Multiplier</label>
                    <input 
                      type="number"
                      className="w-full bg-[#131313] border border-[#4B4A48] rounded px-4 py-3.5 text-sm focus:outline-none focus:border-[#EFD395] transition-all font-black text-[#EFD395] shadow-inner"
                      value={formData.rewardPoints}
                      onChange={e => setFormData({...formData, rewardPoints: parseInt(e.target.value) || 0})}
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-[#777674] ml-1 leading-none">Enrollment No (PS Portal)</label>
                    <input 
                      type="text"
                      className="w-full bg-[#131313] border border-[#4B4A48] rounded px-4 py-3.5 text-sm focus:outline-none focus:border-[#EFD395] transition-all font-black text-[#FFFFFF] italic shadow-inner"
                      placeholder="e.g. 21AD123"
                      value={formData.enrollmentNo}
                      onChange={e => setFormData({...formData, enrollmentNo: e.target.value})}
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-[#A4A4A4] ml-1 leading-none">Activity Index</label>
                    <input 
                      type="number"
                      className="w-full bg-[#131313] border border-[#4B4A48] rounded px-4 py-3.5 text-sm focus:outline-none focus:border-[#777674] transition-all font-black text-[#A4A4A4] shadow-inner"
                      value={formData.activityPoints}
                      onChange={e => setFormData({...formData, activityPoints: parseInt(e.target.value) || 0})}
                    />
                  </div>
                </div>

                <div className="flex gap-4 pt-8 border-t border-[#4B4A48] mt-6">
                  <button 
                    type="button"
                    onClick={() => setShowModal(null)}
                    className="flex-1 px-6 py-4 bg-[#131313] border border-[#4B4A48] hover:bg-[#262625] text-[#FFFFFF] rounded font-black text-[10px] uppercase tracking-widest transition-all active:scale-95"
                  >
                    Discard
                  </button>
                  <button 
                    type="submit"
                    className="flex-1 px-6 py-4 bg-[#EFD395] hover:bg-white text-[#131313] rounded font-black text-[10px] uppercase tracking-widest transition-all shadow-lg active:scale-95"
                  >
                    {showModal === 'create' ? 'Onboard Agent' : 'Sync Changes'}
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}

        {showModal === 'delete' && selectedUser && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-6 sm:p-0">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowModal(null)}
              className="absolute inset-0 bg-black/90 backdrop-blur-xl"
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 20 }}
              className="relative w-full max-w-md bg-[#262625] border border-red-500/20 rounded p-10 text-center shadow-2xl"
            >
              <div className="h-20 w-20 bg-red-500/10 border border-red-500/20 rounded flex items-center justify-center mx-auto mb-8 shadow-inner">
                <Trash2 size={32} className="text-red-500" />
              </div>
              <h3 className="text-2xl font-black text-white uppercase tracking-tighter italic">Terminate Account?</h3>
              <p className="text-[#A4A4A4] text-[10px] mt-4 leading-relaxed font-black uppercase tracking-widest pr-4 pl-4">
                You are about to delete <span className="text-[#EFD395] font-black italic">{selectedUser.name}</span>. This protocol is irreversible and all associated tactical data will be purged.
              </p>

              <div className="flex gap-4 mt-10">
                <button 
                  onClick={() => setShowModal(null)}
                  className="flex-1 px-6 py-4 bg-[#131313] border border-[#4B4A48] hover:bg-[#262625] text-white rounded font-black text-[10px] uppercase tracking-widest transition-all"
                >
                  Cancel
                </button>
                <button 
                  onClick={handleDelete}
                  className="flex-1 px-6 py-4 bg-red-600 hover:bg-red-500 text-white rounded font-black text-[10px] uppercase tracking-widest transition-all shadow-lg active:scale-95"
                >
                  Terminate
                </button>
              </div>
            </motion.div>
          </div>
        )}

        {showModal === 'portfolio' && selectedUser && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-black/80 backdrop-blur-xl">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowModal(null)}
              className="absolute inset-0"
            />
            <motion.div 
              initial={{ scale: 0.95, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.95, opacity: 0, y: 20 }}
              className="relative w-full max-w-4xl bg-[#262625] border border-[#4B4A48] rounded shadow-2xl flex flex-col max-h-[90vh] overflow-hidden"
            >
              <div className="p-10 pb-6 flex justify-between items-start border-b border-[#4B4A48] bg-[#131313]/50">
                <div className="flex items-center gap-6">
                  <div className="h-16 w-16 bg-[#EFD395]/10 border border-[#EFD395]/20 rounded flex items-center justify-center text-[#EFD395] shadow-lg">
                    <LayoutList size={32} />
                  </div>
                  <div>
                    <h3 className="text-3xl font-black text-[#FFFFFF] uppercase tracking-tighter italic">{selectedUser.name}</h3>
                    <p className="text-[10px] font-black text-[#EFD395] uppercase tracking-[0.3em] mt-1 italic">Growth Portfolio Oversight</p>
                  </div>
                </div>
                <button onClick={() => setShowModal(null)} className="p-3 bg-[#131313] border border-[#4B4A48] rounded text-[#777674] hover:text-[#FFFFFF] transition-all">
                  <X size={24} />
                </button>
              </div>

              <div className="flex gap-2 p-6 bg-[#131313]/30 border-b border-[#4B4A48] overflow-x-auto no-scrollbar">
                {[
                  { id: 'skills', label: 'Skill Set', icon: Star },
                  { id: 'learning', label: 'Learning Feed', icon: BookOpen },
                  { id: 'certs', label: 'Achievements', icon: GraduationCap }
                ].map(t => (
                  <button
                    key={t.id}
                    onClick={() => setPortfolioTab(t.id as any)}
                    className={cn(
                      "flex items-center gap-3 px-6 py-3 rounded text-[10px] font-black uppercase tracking-widest border transition-all whitespace-nowrap",
                      portfolioTab === t.id ? "bg-[#EFD395] border-[#EFD395] text-[#131313] shadow-lg shadow-[#EFD395]/10" : "bg-[#131313] border-[#4B4A48] text-[#777674] hover:text-[#A4A4A4]"
                    )}
                  >
                    <t.icon size={16} />
                    {t.label}
                  </button>
                ))}
                <div className="ml-auto flex gap-2">
                  <button 
                    onClick={() => handleExportPortfolio(portfolioTab === 'skills' ? 'skills' : portfolioTab === 'learning' ? 'learning' : 'certifications')}
                    className="flex items-center gap-2.5 px-5 py-3 bg-[#131313] border border-[#4B4A48] text-[#EFD395] rounded text-[10px] font-black uppercase tracking-widest hover:border-[#EFD395]/40 transition-all active:scale-95"
                  >
                    <FileSpreadsheet size={14} />
                    Export {portfolioTab.toUpperCase()}
                  </button>
                </div>
              </div>

              <div className="flex-1 overflow-y-auto p-10 custom-scrollbar no-scrollbar">
                {portfolioLoading ? (
                  <div className="flex flex-col items-center justify-center h-64 gap-6">
                    <div className="h-12 w-12 rounded-full border-2 border-[#EFD395] border-t-transparent animate-spin" />
                    <p className="text-[10px] font-black text-[#777674] uppercase tracking-widest italic animate-pulse">Decrypting Records...</p>
                  </div>
                ) : (
                  <div className="space-y-6">
                    {portfolioTab === 'skills' && (
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {portfolioData.skills.map(s => (
                          <div key={s.id} className="p-6 bg-[#131313] border border-[#4B4A48] rounded flex justify-between items-center group hover:border-[#EFD395]/30 transition-all shadow-inner">
                            <div className="flex gap-4 items-center">
                               <div className="h-10 w-10 bg-[#262625] rounded flex items-center justify-center border border-[#4B4A48] text-[#EFD395]">
                                  <Star size={20} />
                               </div>
                               <div>
                                  <p className="text-base font-black text-[#FFFFFF] leading-tight italic uppercase tracking-tighter">{s.skillName}</p>
                                  <p className="text-[9px] font-black text-[#EFD395] uppercase tracking-widest mt-1 opacity-70">Mastery: {s.type}</p>
                               </div>
                            </div>
                            <button onClick={() => handleDeleteSubItem('skill', s.id)} className="opacity-0 group-hover:opacity-100 p-3 text-red-500 hover:bg-red-500/10 rounded transition-all active:scale-90">
                              <Trash size={18} />
                            </button>
                          </div>
                        ))}
                        {portfolioData.skills.length === 0 && (
                          <div className="col-span-2 py-20 text-center border border-dashed border-[#4B4A48] rounded">
                            <Star size={40} className="mx-auto mb-4 opacity-10 text-[#EFD395]" />
                            <p className="text-[10px] text-[#777674] font-black uppercase tracking-widest italic">No specialized skills registered.</p>
                          </div>
                        )}
                      </div>
                    )}
                    
                    {portfolioTab === 'learning' && (
                      <div className="space-y-4">
                        {portfolioData.learnings.map(l => (
                          <div key={l.id} className="p-6 bg-[#131313] border border-[#4B4A48] rounded flex justify-between items-center group hover:border-[#EFD395]/30 transition-all shadow-inner">
                            <div className="flex gap-5 items-center">
                              <div className="h-12 w-12 bg-[#262625] rounded flex items-center justify-center border border-[#4B4A48] shadow-inner text-[#A4A4A4]">
                                <BookOpen size={24} />
                              </div>
                              <div>
                                <p className="text-lg font-black text-[#FFFFFF] leading-tight uppercase tracking-tight italic">{l.skillName}</p>
                                <div className="flex items-center gap-3 mt-1.5 font-black uppercase text-[9px] tracking-widest">
                                  <span className="px-2.5 py-0.5 bg-[#EFD395]/10 text-[#EFD395] border border-[#EFD395]/20 rounded">{l.level}</span>
                                  <div className="h-1 w-1 rounded-full bg-[#4B4A48]" />
                                  <span className="text-[#A4A4A4] italic">{l.status}</span>
                                </div>
                              </div>
                            </div>
                            <button onClick={() => handleDeleteSubItem('learning', l.id)} className="opacity-0 group-hover:opacity-100 p-3 text-red-500 hover:bg-red-500/10 rounded transition-all active:scale-90">
                              <Trash size={20} />
                            </button>
                          </div>
                        ))}
                        {portfolioData.learnings.length === 0 && (
                          <div className="py-20 text-center border border-dashed border-[#4B4A48] rounded">
                            <BookOpen size={40} className="mx-auto mb-4 opacity-10 text-[#A4A4A4]" />
                            <p className="text-[10px] text-[#777674] font-black uppercase tracking-widest italic">Active learning stream is empty.</p>
                          </div>
                        )}
                      </div>
                    )}

                    {portfolioTab === 'certs' && (
                      <div className="space-y-4">
                        {portfolioData.certs.map(c => (
                          <div key={c.id} className="p-6 bg-[#131313] border border-[#4B4A48] rounded flex justify-between items-center group hover:border-[#EFD395]/30 transition-all shadow-inner">
                            <div className="flex gap-5 items-center">
                              <div className="h-14 w-14 bg-[#262625] rounded flex items-center justify-center border border-[#4B4A48] shadow-inner text-[#EFD395]">
                                <GraduationCap size={32} />
                              </div>
                              <div>
                                <p className="text-lg font-black text-[#FFFFFF] leading-none uppercase tracking-tight italic">{c.skill}</p>
                                <p className="text-[10px] text-[#EFD395] font-black uppercase tracking-widest mt-3 opacity-60">Validated by: {c.provider}</p>
                              </div>
                            </div>
                            <div className="flex gap-2">
                              {c.fileUrl && (
                                <a 
                                  href={c.fileUrl} 
                                  target="_blank" 
                                  rel="noopener noreferrer"
                                  className="p-3 bg-[#262625] text-[#A4A4A4] hover:text-[#EFD395] rounded transition-all active:scale-90 flex items-center gap-2 text-[10px] font-black uppercase tracking-widest border border-[#4B4A48] hover:border-[#EFD395]/40"
                                >
                                  <ExternalLink size={18} />
                                  Proof
                                </a>
                              )}
                              <button onClick={() => handleDeleteSubItem('cert', c.id)} className="opacity-0 group-hover:opacity-100 p-3 text-red-500 hover:bg-red-500/10 rounded transition-all active:scale-90">
                                <Trash size={20} />
                              </button>
                            </div>
                          </div>
                        ))}
                        {portfolioData.certs.length === 0 && (
                          <div className="py-20 text-center border border-dashed border-[#4B4A48] rounded">
                            <GraduationCap size={40} className="mx-auto mb-4 opacity-10 text-[#EFD395]" />
                            <p className="text-[10px] text-[#777674] font-black uppercase tracking-widest italic">No verified achievements documented.</p>
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                )}
              </div>

              <div className="p-8 bg-[#131313]/80 border-t border-[#4B4A48] text-center">
                <p className="text-[9px] font-black text-[#777674] uppercase tracking-[0.5em] italic">Synchronized at {new Date().toLocaleTimeString()}</p>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
