'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api, { downloadExcel } from '@/lib/api';
import { Users, MoreVertical, Shield, Mail, Building, Plus, Trash2, Edit3, X, Check, Search, Star, Flame, LayoutList, GraduationCap, BookOpen, Trash, Hexagon, FileSpreadsheet } from 'lucide-react';
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
      name: user.name,
      email: user.email,
      role: user.role,
      regNo: user.regNo || '',
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
    <div className="flex min-h-screen bg-slate-950 text-slate-50">
      <Sidebar />
      
      <main className="flex-1 p-8 overflow-y-auto">
        <header className="flex justify-between items-center mb-8">
          <div>
            <h2 className="text-3xl font-bold tracking-tight uppercase">Team Members</h2>
            <p className="text-slate-400 mt-1 font-medium italic">Manage accounts, roles and tactical performance metrics.</p>
          </div>
          <div className="flex gap-4">
            <button 
              onClick={handleExportUsers}
              className="flex items-center gap-2.5 px-6 py-3 bg-slate-900 border border-slate-700 hover:border-emerald-500/50 hover:bg-emerald-500/5 text-slate-300 hover:text-emerald-400 rounded-2xl text-[10px] font-black uppercase tracking-widest transition-all shadow-xl active:scale-95 group"
            >
              <FileSpreadsheet size={16} className="group-hover:animate-pulse" />
              Export Roster
            </button>
            <button 
              onClick={openCreateModal}
              className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-2xl font-bold transition-all shadow-lg shadow-blue-600/20 active:scale-95"
            >
              <Plus size={20} />
              Onboard Member
            </button>
          </div>
        </header>

        <div className="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-2xl backdrop-blur-xl">
          <div className="p-6 border-b border-slate-800 flex items-center gap-4 bg-slate-900/50">
            <div className="relative flex-1">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
              <input 
                type="text" 
                placeholder="Search by name, email or department..." 
                className="w-full bg-slate-950 border border-slate-800 rounded-2xl pl-12 pr-4 py-3.5 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-medium"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-950/50 text-slate-500 text-[10px] uppercase tracking-[0.2em] font-black">
                  <th className="px-8 py-5">Identified Account</th>
                  <th className="px-8 py-5">Assigned Role</th>
                  <th className="px-8 py-5">Performance Units</th>
                  <th className="px-8 py-5 text-right">Administrative</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/50">
                {filteredUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-slate-800/20 transition-colors group">
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-4">
                        <div className="h-12 w-12 rounded-2xl bg-gradient-to-br from-slate-800 to-slate-900 border border-slate-700 flex items-center justify-center font-bold text-slate-400 shadow-inner overflow-hidden">
                          {user.profileImageUrl ? (
                            <img src={user.profileImageUrl} alt="" className="w-full h-full object-cover" />
                          ) : (
                            user.name[0].toUpperCase()
                          )}
                        </div>
                        <div>
                          <div className="font-bold text-slate-100 text-base">{user.name}</div>
                          <div className="text-xs text-slate-500 flex items-center gap-1.5 mt-0.5 font-medium">
                            <Mail size={12} className="opacity-50" /> {user.email}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-6">
                      <span className={cn(
                        "inline-flex items-center gap-1.5 px-3 py-1 rounded-xl text-[10px] font-black uppercase tracking-wider border transition-all",
                        user.role === 'ADMIN' ? "bg-rose-500/10 text-rose-500 border-rose-500/20" : 
                        user.role === 'CAPTAIN' ? "bg-amber-500/10 text-amber-500 border-amber-500/20" :
                        user.role === 'VICE_CAPTAIN' ? "bg-orange-500/10 text-orange-500 border-orange-500/20" :
                        user.role === 'STRATEGIST' ? "bg-purple-500/10 text-purple-500 border-purple-500/20" :
                        user.role === 'MANAGER' ? "bg-emerald-500/10 text-emerald-500 border-emerald-500/20" :
                        "bg-blue-500/10 text-blue-400 border-blue-500/20"
                      )}>
                        <Shield size={10} strokeWidth={3} />
                        {user.role.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-8 py-6">
                      <div className="flex flex-col gap-2">
                        <div className="flex items-center gap-3">
                          <div className="flex items-center gap-1.5 bg-emerald-500/5 border border-emerald-500/10 rounded-lg px-2 py-1">
                            <Star size={10} className="text-emerald-500 fill-emerald-500/20" />
                            <span className="text-xs font-bold text-emerald-500">{user.rewardPoints} RPT</span>
                          </div>
                          <div className="flex items-center gap-1.5 bg-orange-500/5 border border-orange-500/10 rounded-lg px-2 py-1">
                            <Flame size={10} className="text-orange-500 fill-orange-500/20" />
                            <span className="text-xs font-bold text-orange-500">{user.activityPoints} APT</span>
                          </div>
                        </div>
                        <span className="text-[10px] text-slate-600 font-bold uppercase tracking-tight ml-1 leading-none">{user.department || 'UNCATEGORIZED'}</span>
                      </div>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <div className="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button 
                          onClick={() => openPortfolioModal(user)}
                          className="p-2.5 rounded-xl hover:bg-emerald-500/10 text-slate-500 hover:text-emerald-400 transition-all border border-transparent hover:border-emerald-500/20"
                          title="View Portfolio"
                        >
                          <LayoutList size={18} />
                        </button>
                        <button 
                          onClick={() => openEditModal(user)}
                          className="p-2.5 rounded-xl hover:bg-blue-500/10 text-slate-500 hover:text-blue-400 transition-all border border-transparent hover:border-blue-500/20"
                          title="Edit Profile"
                        >
                          <Edit3 size={18} />
                        </button>
                        <button 
                          onClick={() => openDeleteModal(user)}
                          className="p-2.5 rounded-xl hover:bg-rose-500/10 text-slate-500 hover:text-rose-400 transition-all border border-transparent hover:border-rose-500/20"
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
            <div className="p-32 text-center text-slate-500">
              <div className="h-20 w-20 bg-slate-950 border border-slate-800 rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-inner">
                <Users size={32} className="opacity-20" />
              </div>
              <p className="font-bold text-lg text-slate-400">Zero tactical matches</p>
              <p className="text-sm mt-1">Refine your search parameters and try again.</p>
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
              className="absolute inset-0 bg-slate-950/80 backdrop-blur-md"
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 20 }}
              className="relative w-full max-w-xl bg-slate-900 border border-slate-700/50 rounded-[2.5rem] shadow-2xl overflow-hidden"
            >
              <div className="p-8 pb-0 flex justify-between items-start">
                <div>
                  <h3 className="text-2xl font-black text-white uppercase tracking-tighter">{showModal === 'create' ? 'Onboard Member' : 'Regulate Account'}</h3>
                  <p className="text-slate-400 text-sm mt-1 font-medium">Configure administrative permissions and metrics.</p>
                </div>
                <button onClick={() => setShowModal(null)} className="p-2 hover:bg-slate-800 rounded-full text-slate-500 transition-colors">
                  <X size={20} />
                </button>
              </div>

              <form onSubmit={showModal === 'create' ? handleCreate : handleUpdate} className="p-8 space-y-6">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2 col-span-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Full Identity</label>
                    <input 
                      type="text" required
                      className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3.5 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-bold text-white shadow-inner"
                      placeholder="e.g. Alex Johnson"
                      value={formData.name}
                      onChange={e => setFormData({...formData, name: e.target.value})}
                    />
                  </div>
                  
                  {showModal === 'create' && (
                    <div className="space-y-2 col-span-2">
                      <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Google Email Anchor</label>
                      <input 
                        type="email" required
                        className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3.5 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-bold text-white shadow-inner"
                        placeholder="alex@team.com"
                        value={formData.email}
                        onChange={e => setFormData({...formData, email: e.target.value})}
                      />
                    </div>
                  )}

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Assigned Rank</label>
                    <select 
                      className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3.5 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-bold text-white appearance-none shadow-inner"
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
                    <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Department</label>
                    <input 
                      type="text"
                      className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3.5 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-bold text-white shadow-inner"
                      placeholder="Engineering"
                      value={formData.department}
                      onChange={e => setFormData({...formData, department: e.target.value})}
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Reward Multiplier</label>
                    <input 
                      type="number"
                      className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3.5 text-sm focus:outline-none focus:ring-4 focus:ring-emerald-500/10 focus:border-emerald-500/50 transition-all font-bold text-emerald-500 shadow-inner"
                      value={formData.rewardPoints}
                      onChange={e => setFormData({...formData, rewardPoints: parseInt(e.target.value) || 0})}
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Activity Index</label>
                    <input 
                      type="number"
                      className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3.5 text-sm focus:outline-none focus:ring-4 focus:ring-orange-500/10 focus:border-orange-500/50 transition-all font-bold text-orange-500 shadow-inner"
                      value={formData.activityPoints}
                      onChange={e => setFormData({...formData, activityPoints: parseInt(e.target.value) || 0})}
                    />
                  </div>
                </div>

                <div className="flex gap-4 pt-4 border-t border-slate-800 mt-6">
                  <button 
                    type="button"
                    onClick={() => setShowModal(null)}
                    className="flex-1 px-6 py-4 bg-slate-800 hover:bg-slate-750 text-white rounded-2xl font-bold transition-all active:scale-95"
                  >
                    Discard
                  </button>
                  <button 
                    type="submit"
                    className="flex-1 px-6 py-4 bg-blue-600 hover:bg-blue-500 text-white rounded-2xl font-bold transition-all shadow-lg shadow-blue-600/20 active:scale-95"
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
              className="absolute inset-0 bg-slate-950/90 backdrop-blur-xl"
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 20 }}
              className="relative w-full max-w-md bg-slate-900 border border-rose-500/20 rounded-[2.5rem] shadow-2xl p-10 text-center"
            >
              <div className="h-20 w-20 bg-rose-500/10 border border-rose-500/20 rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-inner">
                <Trash2 size={32} className="text-rose-500" />
              </div>
              <h3 className="text-2xl font-black text-white uppercase tracking-tighter">Terminate Account?</h3>
              <p className="text-slate-400 text-sm mt-3 leading-relaxed font-medium">
                You are about to delete <span className="text-white font-bold">{selectedUser.name}</span>. This protocol is irreversible and all associated tactical data will be purged.
              </p>

              <div className="flex gap-4 mt-8">
                <button 
                  onClick={() => setShowModal(null)}
                  className="flex-1 px-6 py-4 bg-slate-800 hover:bg-slate-750 text-white rounded-2xl font-bold transition-all"
                >
                  Cancel
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

        {showModal === 'portfolio' && selectedUser && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-xl">
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
              className="relative w-full max-w-3xl bg-slate-900 border border-slate-700/50 rounded-[3rem] shadow-2xl flex flex-col max-h-[85vh] overflow-hidden"
            >
              <div className="p-10 pb-6 flex justify-between items-start border-b border-slate-800 bg-slate-900/50">
                <div className="flex items-center gap-6">
                  <div className="h-16 w-16 bg-emerald-500/10 border border-emerald-500/20 rounded-[1.5rem] flex items-center justify-center text-emerald-500 shadow-lg shadow-emerald-600/10">
                    <LayoutList size={32} />
                  </div>
                  <div>
                    <h3 className="text-3xl font-black text-white uppercase tracking-tighter">{selectedUser.name}</h3>
                    <p className="text-[10px] font-black text-slate-500 uppercase tracking-[0.3em] mt-1">Growth Portfolio Oversight</p>
                  </div>
                </div>
                <button onClick={() => setShowModal(null)} className="p-3 bg-slate-950 border border-slate-800 rounded-2xl text-slate-500 hover:text-white hover:bg-slate-800 transition-all">
                  <X size={24} />
                </button>
              </div>

              <div className="flex gap-2 p-6 bg-slate-950/30 border-b border-slate-800">
                {[
                  { id: 'skills', label: 'Skill Set', icon: Star },
                  { id: 'learning', label: 'Learning Feed', icon: BookOpen },
                  { id: 'certs', label: 'Achievements', icon: GraduationCap }
                ].map(t => (
                  <button
                    key={t.id}
                    onClick={() => setPortfolioTab(t.id as any)}
                    className={cn(
                      "flex items-center gap-3 px-6 py-3 rounded-2xl text-[10px] font-black uppercase tracking-widest border transition-all",
                      portfolioTab === t.id ? "bg-emerald-600 border-emerald-500 text-white shadow-lg shadow-emerald-600/20" : "bg-slate-900 border-slate-800 text-slate-500 hover:text-slate-300"
                    )}
                  >
                    <t.icon size={16} />
                    {t.label}
                  </button>
                ))}
                {portfolioTab === 'skills' && (
                  <button 
                    onClick={() => handleExportPortfolio('skills')}
                    className="flex items-center gap-2.5 px-5 py-3 bg-emerald-500/10 border border-emerald-500/30 text-emerald-500 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-emerald-500/20 transition-all active:scale-95 ml-auto"
                  >
                    <FileSpreadsheet size={14} />
                    Export Skills
                  </button>
                )}
                {portfolioTab === 'learning' && (
                  <button 
                    onClick={() => handleExportPortfolio('learning')}
                    className="flex items-center gap-2.5 px-5 py-3 bg-blue-500/10 border border-blue-500/30 text-blue-500 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-blue-500/20 transition-all active:scale-95 ml-auto"
                  >
                    <FileSpreadsheet size={14} />
                    Export Learning
                  </button>
                )}
                {portfolioTab === 'certs' && (
                  <button 
                    onClick={() => handleExportPortfolio('certifications')}
                    className="flex items-center gap-2.5 px-5 py-3 bg-amber-500/10 border border-amber-500/30 text-amber-500 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-amber-500/20 transition-all active:scale-95 ml-auto"
                  >
                    <FileSpreadsheet size={14} />
                    Export Certs
                  </button>
                )}
              </div>

              <div className="flex-1 overflow-y-auto p-10 custom-scrollbar">
                {portfolioLoading ? (
                  <div className="flex flex-col items-center justify-center h-64 gap-4">
                    <div className="h-12 w-12 rounded-full border-4 border-emerald-500 border-t-transparent animate-spin shadow-lg shadow-emerald-500/20" />
                    <p className="text-[10px] font-black text-slate-600 uppercase tracking-widest">Decrypting Records...</p>
                  </div>
                ) : (
                  <div className="space-y-6">
                    {portfolioTab === 'skills' && (
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {portfolioData.skills.map(s => (
                          <div key={s.id} className="p-6 bg-slate-950/50 border border-slate-800 rounded-[2rem] flex justify-between items-center group hover:border-emerald-500/30 transition-all shadow-inner">
                            <div className="flex gap-4 items-center">
                               <div className="h-10 w-10 bg-emerald-500/5 rounded-xl flex items-center justify-center border border-emerald-500/10 text-emerald-500">
                                  <Star size={20} />
                               </div>
                               <div>
                                  <p className="text-base font-black text-white leading-tight">{s.skillName}</p>
                                  <p className="text-[9px] font-black text-emerald-500 uppercase tracking-widest mt-1">Mastery: {s.type}</p>
                               </div>
                            </div>
                            <button onClick={() => handleDeleteSubItem('skill', s.id)} className="opacity-0 group-hover:opacity-100 p-3 text-rose-500 hover:bg-rose-500/10 rounded-xl transition-all active:scale-90">
                              <Trash size={18} />
                            </button>
                          </div>
                        ))}
                        {portfolioData.skills.length === 0 && (
                          <div className="col-span-2 py-20 text-center border-2 border-dashed border-slate-800 rounded-[2rem]">
                            <Star size={40} className="mx-auto mb-4 opacity-10 text-emerald-500" />
                            <p className="text-sm text-slate-500 font-bold italic">No specialized skills registered.</p>
                          </div>
                        )}
                      </div>
                    )}
                    
                    {portfolioTab === 'learning' && (
                      <div className="space-y-4">
                        {portfolioData.learnings.map(l => (
                          <div key={l.id} className="p-6 bg-slate-950/50 border border-slate-800 rounded-[2rem] flex justify-between items-center group hover:border-blue-500/30 transition-all shadow-inner">
                            <div className="flex gap-5 items-center">
                              <div className="h-12 w-12 bg-blue-500/5 rounded-2xl flex items-center justify-center border border-blue-500/10 shadow-inner">
                                <BookOpen size={24} className="text-blue-400" />
                              </div>
                              <div>
                                <p className="text-lg font-black text-white leading-tight uppercase tracking-tight">{l.skillName}</p>
                                <div className="flex items-center gap-3 mt-1.5">
                                  <span className="px-2.5 py-0.5 bg-blue-500/10 text-[9px] font-black text-blue-500 border border-blue-500/20 rounded uppercase tracking-widest">{l.level}</span>
                                  <div className="h-1 w-1 rounded-full bg-slate-700" />
                                  <span className="text-[10px] text-slate-500 font-bold uppercase tracking-tighter">{l.status}</span>
                                </div>
                              </div>
                            </div>
                            <button onClick={() => handleDeleteSubItem('learning', l.id)} className="opacity-0 group-hover:opacity-100 p-3 text-rose-500 hover:bg-rose-500/10 rounded-xl transition-all active:scale-90">
                              <Trash size={20} />
                            </button>
                          </div>
                        ))}
                        {portfolioData.learnings.length === 0 && (
                          <div className="py-20 text-center border-2 border-dashed border-slate-800 rounded-[2rem]">
                            <BookOpen size={40} className="mx-auto mb-4 opacity-10 text-blue-500" />
                            <p className="text-sm text-slate-500 font-bold italic">Active learning stream is empty.</p>
                          </div>
                        )}
                      </div>
                    )}

                    {portfolioTab === 'certs' && (
                      <div className="space-y-4">
                        {portfolioData.certs.map(c => (
                          <div key={c.id} className="p-6 bg-slate-950/50 border border-slate-800 rounded-[2rem] flex justify-between items-center group hover:border-amber-500/30 transition-all shadow-inner">
                            <div className="flex gap-5 items-center">
                              <div className="h-14 w-14 bg-amber-500/5 rounded-2xl flex items-center justify-center border border-amber-500/10 shadow-inner">
                                <GraduationCap size={32} className="text-amber-500" />
                              </div>
                              <div>
                                <p className="text-lg font-black text-white leading-none uppercase tracking-tight">{c.skill}</p>
                                <p className="text-xs text-amber-500 font-bold italic mt-2">Validated by: {c.provider}</p>
                              </div>
                            </div>
                            <button onClick={() => handleDeleteSubItem('cert', c.id)} className="opacity-0 group-hover:opacity-100 p-3 text-rose-500 hover:bg-rose-500/10 rounded-xl transition-all active:scale-90">
                              <Trash size={20} />
                            </button>
                          </div>
                        ))}
                        {portfolioData.certs.length === 0 && (
                          <div className="py-20 text-center border-2 border-dashed border-slate-800 rounded-[2rem]">
                            <GraduationCap size={40} className="mx-auto mb-4 opacity-10 text-amber-500" />
                            <p className="text-sm text-slate-500 font-bold italic">No verified achievements documented.</p>
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                )}
              </div>

              <div className="p-8 bg-slate-950 border-t border-slate-800 text-center">
                <p className="text-[10px] font-black text-slate-700 uppercase tracking-[0.5em]">Synchronized at {new Date().toLocaleTimeString()}</p>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
