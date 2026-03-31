'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { Users, MoreVertical, Shield, Mail, Building, Plus, Trash2, Edit3, X, Check, Search, Star, Flame } from 'lucide-react';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';

export default function MembersPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState<'create' | 'edit' | 'delete' | null>(null);
  const [selectedUser, setSelectedUser] = useState<any>(null);
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
            <h2 className="text-3xl font-bold tracking-tight">Team Members</h2>
            <p className="text-slate-400 mt-1">Manage accounts, roles and performance metrics</p>
          </div>
          <button 
            onClick={openCreateModal}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-2xl font-bold transition-all shadow-lg shadow-blue-600/20 active:scale-95"
          >
            <Plus size={20} />
            New Member
          </button>
        </header>

        <div className="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-2xl backdrop-blur-xl">
          <div className="p-6 border-b border-slate-800 flex items-center gap-4 bg-slate-900/50">
            <div className="relative flex-1">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
              <input 
                type="text" 
                placeholder="Search by name, email or department..." 
                className="w-full bg-slate-950 border border-slate-800 rounded-2xl pl-12 pr-4 py-3 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-medium"
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
                        <div className="h-12 w-12 rounded-2xl bg-gradient-to-br from-slate-800 to-slate-900 border border-slate-700 flex items-center justify-center font-bold text-slate-400 shadow-inner">
                          {user.profileImageUrl ? (
                            <img src={user.profileImageUrl} alt="" className="w-full h-full rounded-2xl object-cover" />
                          ) : (
                            user.name[0].toUpperCase()
                          )}
                        </div>
                        <div>
                          <div className="font-bold text-slate-100 text-base">{user.name}</div>
                          <div className="text-xs text-slate-500 flex items-center gap-1.5 mt-0.5">
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
                        <span className="text-[10px] text-slate-600 font-bold uppercase tracking-tight ml-1">{user.department || 'UNCATEGORIZED'}</span>
                      </div>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <div className="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button 
                          onClick={() => openEditModal(user)}
                          className="p-2.5 rounded-xl hover:bg-blue-500/10 text-slate-500 hover:text-blue-400 transition-all border border-transparent hover:border-blue-500/20"
                        >
                          <Edit3 size={18} />
                        </button>
                        <button 
                          onClick={() => openDeleteModal(user)}
                          className="p-2.5 rounded-xl hover:bg-rose-500/10 text-slate-500 hover:text-rose-400 transition-all border border-transparent hover:border-rose-500/20"
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
              <p className="font-bold text-lg text-slate-400">Zero matches found</p>
              <p className="text-sm mt-1">Refine your search parameters and try again.</p>
            </div>
          )}
        </div>
      </main>

      {/* Modals */}
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
                  <h3 className="text-2xl font-black text-white">{showModal === 'create' ? 'Onboard Member' : 'Regulate Account'}</h3>
                  <p className="text-slate-400 text-sm mt-1">Configure administrative permissions and metrics.</p>
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
                      className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-medium text-white"
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
                        className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-medium text-white"
                        placeholder="alex@team.com"
                        value={formData.email}
                        onChange={e => setFormData({...formData, email: e.target.value})}
                      />
                    </div>
                  )}

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Assigned Rank</label>
                    <select 
                      className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-medium text-white appearance-none"
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
                      className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3 text-sm focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500/50 transition-all font-medium text-white"
                      placeholder="Engineering"
                      value={formData.department}
                      onChange={e => setFormData({...formData, department: e.target.value})}
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Reward Multiplier</label>
                    <input 
                      type="number"
                      className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3 text-sm focus:outline-none focus:ring-4 focus:ring-emerald-500/10 focus:border-emerald-500/50 transition-all font-bold text-emerald-500"
                      value={formData.rewardPoints}
                      onChange={e => setFormData({...formData, rewardPoints: parseInt(e.target.value) || 0})}
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="text-[10px] uppercase font-black tracking-widest text-slate-500 ml-1">Activity Index</label>
                    <input 
                      type="number"
                      className="w-full bg-slate-950 border border-slate-800 rounded-2xl px-4 py-3 text-sm focus:outline-none focus:ring-4 focus:ring-orange-500/10 focus:border-orange-500/50 transition-all font-bold text-orange-500"
                      value={formData.activityPoints}
                      onChange={e => setFormData({...formData, activityPoints: parseInt(e.target.value) || 0})}
                    />
                  </div>
                </div>

                <div className="flex gap-4 pt-4">
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
                    {showModal === 'create' ? 'Complete Onboarding' : 'Sync Changes'}
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}

        {showModal === 'delete' && (
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
              className="relative w-full max-w-md bg-slate-900 border border-rose-500/20 rounded-[2rem] shadow-2xl p-8 text-center"
            >
              <div className="h-20 w-20 bg-rose-500/10 border border-rose-500/20 rounded-3xl flex items-center justify-center mx-auto mb-6">
                <Trash2 size={32} className="text-rose-500" />
              </div>
              <h3 className="text-2xl font-black text-white">Terminate Account?</h3>
              <p className="text-slate-400 text-sm mt-2 leading-relaxed">
                You are about to delete <span className="text-white font-bold">{selectedUser?.name}</span>. This protocol is irreversible and all associated data will be purged.
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
                  className="flex-1 px-6 py-4 bg-rose-600 hover:bg-rose-500 text-white rounded-2xl font-bold transition-all shadow-lg shadow-rose-600/20 active:scale-95"
                >
                  Terminate
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
