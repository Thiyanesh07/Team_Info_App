'use client';
import { useState, useEffect } from 'react';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { Search, UserCircle, Calendar, Briefcase, GraduationCap, Zap, Activity, ChevronRight } from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';

export default function InspectionPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [users, setUsers] = useState<any[]>([]);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [userDetail, setUserDetail] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (searchQuery.length > 2) {
      searchUsers();
    }
  }, [searchQuery]);

  const searchUsers = async () => {
    try {
      const res = await api.get('/users');
      if (res.data.success) {
        setUsers(res.data.data.filter((u: any) => 
          u.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
          u.email.toLowerCase().includes(searchQuery.toLowerCase())
        ));
      }
    } catch (err) {
      console.error('Search error:', err);
    }
  };

  const fetchUserDetail = async (userId: string) => {
    setLoading(true);
    try {
      const res = await api.get(`/admin/users/${userId}/detail`);
      if (res.data.success) {
        setUserDetail(res.data.data);
        setSelectedUser(users.find(u => u.id === userId));
      }
    } catch (err) {
      console.error('Detail fetch error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen bg-[#131313] text-[#FFFFFF]">
      <Sidebar />
      
      <main className="flex-1 p-8 overflow-y-auto custom-scrollbar no-scrollbar mt-16 lg:mt-0">
        <header className="mb-12 border-b border-[#4B4A48] pb-10">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-4xl md:text-6xl font-black tracking-tighter text-[#FFFFFF] uppercase italic">Performance Inspection</h2>
            <p className="text-[#A4A4A4] mt-1 text-[10px] md:text-xs font-black uppercase tracking-[0.2em] opacity-60">Deep-dive into team member history and accountability.</p>
          </motion.div>
        </header>

        <div className="max-w-4xl mx-auto space-y-12">
          {/* Search Bar */}
          <div className="relative group">
            <Search className="absolute left-5 top-1/2 -translate-y-1/2 text-[#4B4A48] group-focus-within:text-[#EFD395] transition-colors" size={24} />
            <input 
              type="text" 
              placeholder="Search by name or email to inspect..." 
              className="w-full bg-[#262625] border border-[#4B4A48] rounded pl-16 pr-6 py-6 text-xl focus:outline-none focus:border-[#EFD395] transition-all font-black uppercase italic shadow-2xl shadow-black/50"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            
            {/* Search Results Dropdown */}
            {searchQuery.length > 2 && users.length > 0 && !selectedUser && (
              <div className="absolute top-full left-0 right-0 mt-4 bg-[#262625] border border-[#4B4A48] rounded shadow-2xl z-50 overflow-hidden divide-y divide-[#4B4A48]/30">
                {users.map(user => (
                  <button 
                    key={user.id}
                    onClick={() => {
                      fetchUserDetail(user.id);
                      setSearchQuery('');
                    }}
                    className="w-full text-left p-6 hover:bg-[#131313] flex items-center gap-6 transition-all group"
                  >
                    <div className="h-14 w-14 rounded bg-[#131313] border border-[#4B4A48] flex items-center justify-center font-black text-[#EFD395] overflow-hidden italic shadow-inner group-hover:border-[#EFD395]">
                      {user.profileImageUrl ? (
                        <img src={user.profileImageUrl} alt="" className="w-full h-full object-cover" />
                      ) : (
                        user.name[0]
                      )}
                    </div>
                    <div>
                      <p className="font-black text-white uppercase italic tracking-tight text-lg">{user.name}</p>
                      <p className="text-[10px] font-black text-[#777674] uppercase tracking-[0.2em] italic border-l-2 border-[#4B4A48]/30 pl-3 mt-1 group-hover:border-[#EFD395] transition-colors">{user.email} • {user.role}</p>
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>

          {loading && (
            <div className="text-center py-24">
              <div className="h-16 w-16 border-4 border-[#EFD395]/10 border-t-[#EFD395] rounded-full mx-auto animate-spin"></div>
              <p className="text-[#EFD395] mt-6 font-black uppercase tracking-[0.4em] italic text-xs animate-pulse">Scanning historical records...</p>
            </div>
          )}

          {userDetail && selectedUser && !loading && (
            <div className="space-y-12 animate-in fade-in slide-in-from-bottom-6 duration-700 pb-20">
              {/* User Profiler Header */}
              <div className="bg-[#262625] border border-[#4B4A48] p-10 md:p-14 rounded flex flex-col md:flex-row items-center gap-10 shadow-2xl relative overflow-hidden group">
                <div className="absolute top-0 right-0 w-64 h-64 bg-[#EFD395]/5 blur-[100px] pointer-events-none"></div>
                <div className="h-32 w-32 rounded bg-[#131313] border-2 border-[#4B4A48] flex-shrink-0 flex items-center justify-center text-5xl font-black text-[#EFD395] shadow-inner italic overflow-hidden group-hover:border-[#EFD395] transition-colors">
                  {selectedUser.profileImageUrl ? (
                    <img src={selectedUser.profileImageUrl} alt="" className="w-full h-full object-cover" />
                  ) : (
                    selectedUser.name[0]
                  )}
                </div>
                <div className="flex-1 text-center md:text-left z-10">
                  <h3 className="text-4xl md:text-5xl font-black tracking-tighter text-white uppercase italic mb-6 leading-none">{selectedUser.name}</h3>
                  <div className="flex flex-wrap justify-center md:justify-start gap-4">
                    <span className="px-5 py-2 bg-[#131313] text-[#EFD395] rounded text-[10px] font-black uppercase tracking-[0.2em] border border-[#4B4A48] italic">{selectedUser.role}</span>
                    <span className="px-5 py-2 bg-[#131313] text-[#A4A4A4] rounded text-[10px] font-black uppercase tracking-[0.2em] border border-[#4B4A48] italic">{selectedUser.department || 'General Forces'}</span>
                    <span className="px-5 py-2 bg-[#131313] text-[#777674] rounded text-[10px] font-black uppercase tracking-[0.2em] border border-[#4B4A48] italic">{selectedUser.email}</span>
                  </div>
                </div>
                <div className="absolute bottom-4 right-6 text-[#131313] font-black text-[80px] uppercase italic tracking-tighter opacity-[0.03] select-none pointer-events-none">PROFILE</div>
              </div>

              {/* History Modules */}
              <div className="grid grid-cols-1 gap-8">
                {/* 1. Project Updates */}
                <HistoryModule 
                  title="Project Footprint" 
                  icon={Briefcase} 
                  color="text-[#EFD395]"
                  emptyText="No recorded project contributions yet."
                >
                  <div className="space-y-6">
                    {userDetail.projectUpdates?.map((up: any) => (
                      <div key={up.id} className="p-8 bg-[#131313] rounded border border-[#4B4A48] hover:border-[#EFD395]/30 transition-colors group/card relative overflow-hidden">
                        <div className="flex justify-between items-start mb-6 relative z-10">
                          <h5 className="font-black text-white uppercase italic tracking-tight text-lg">{up.title}</h5>
                          <time className="text-[10px] text-[#EFD395] font-black uppercase tracking-widest italic bg-[#262625] px-3 py-1 rounded shadow-inner">{format(new Date(up.date), 'MMM dd, yyyy')}</time>
                        </div>
                        <p className="text-sm text-[#A4A4A4] leading-relaxed italic border-l-2 border-[#4B4A48]/30 pl-6 group-hover/card:border-[#EFD395]/40 transition-colors relative z-10">{up.description}</p>
                        <div className="mt-6 flex items-center gap-3 relative z-10">
                          <Activity size={12} className="text-[#EFD395]" />
                          <span className="text-[9px] font-black text-[#777674] uppercase tracking-widest italic group-hover/card:text-[#FFFFFF] transition-colors">Campaign: <span className="text-[#EFD395]">{up.project?.projectName}</span></span>
                        </div>
                        <div className="absolute right-0 bottom-0 w-24 h-24 bg-gradient-to-tl from-[#EFD395]/5 to-transparent pointer-events-none" />
                      </div>
                    ))}
                  </div>
                </HistoryModule>

                {/* 2. Tasks */}
                <HistoryModule 
                  title="Operational Accountability" 
                  icon={Zap} 
                  color="text-[#EFD395]"
                  emptyText="No tasks assigned to this user."
                >
                  <div className="space-y-4">
                    {userDetail.tasksReceived?.map((t: any) => (
                      <div key={t.id} className="p-6 bg-[#131313] rounded border border-[#4B4A48] flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 group/task">
                        <div className="flex items-center gap-6">
                          <div className="h-2 w-2 rounded-full bg-[#EFD395] shadow-[0_0_8px_rgba(239,211,149,0.5)] group-hover/task:scale-125 transition-transform" />
                          <div>
                            <h5 className="font-black text-white uppercase italic tracking-tight">{t.title}</h5>
                            <p className="text-[10px] text-[#777674] font-black uppercase tracking-[0.2em] italic mt-1">Originating Agent: {t.assignedBy?.name}</p>
                          </div>
                        </div>
                        <div className={cn(
                          "px-4 py-1.5 rounded border text-[9px] font-black uppercase tracking-[0.3em] inline-flex items-center gap-2 italic",
                          t.status === 'COMPLETED' ? "bg-[#EFD395]/10 text-[#EFD395] border-[#EFD395]/20 shadow-inner" : 
                          "bg-[#131313] text-[#777674] border-[#4B4A48]"
                        )}>
                          {t.status === 'COMPLETED' && <Activity size={10} />}
                          {t.status.replace('_', ' ')}
                        </div>
                      </div>
                    ))}
                  </div>
                </HistoryModule>

                {/* 3. Learning Path */}
                <HistoryModule 
                  title="Skill Intelligence" 
                  icon={GraduationCap} 
                  color="text-[#EFD395]"
                  emptyText="No registered learning activities."
                >
                   <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                     {userDetail.learnings?.map((l: any) => (
                      <div key={l.id} className="p-6 bg-[#131313] rounded border border-[#4B4A48] flex items-center justify-between group/skill hover:border-[#EFD395]/30 transition-colors">
                        <div className="flex items-center gap-5">
                          <div className="p-3 bg-[#262625] rounded border border-[#4B4A48] text-[#EFD395] group-hover/skill:border-[#EFD395] transition-colors">
                            <Activity size={18} />
                          </div>
                          <div>
                            <h5 className="font-black text-white uppercase italic tracking-tight">{l.skillName}</h5>
                            <p className="text-[10px] text-[#777674] font-black uppercase tracking-[0.2em] italic mt-1">
                              {l.startDate && format(new Date(l.startDate), 'MMM yyyy')} - {l.endDate ? format(new Date(l.endDate), 'MMM yyyy') : 'Operational'}
                            </p>
                          </div>
                        </div>
                        <span className="bg-[#262625] px-4 py-1.5 rounded text-[10px] font-black text-[#EFD395] border border-[#4B4A48] uppercase italic">{l.level}</span>
                      </div>
                    ))}
                   </div>
                </HistoryModule>
              </div>
            </div>
          )}

          {!selectedUser && !loading && (
            <div className="py-32 text-center text-[#4B4A48] border border-dashed border-[#4B4A48] rounded group">
              <UserCircle size={80} className="mx-auto opacity-20 mb-8 group-hover:text-[#EFD395] group-hover:opacity-40 transition-all group-hover:scale-110 duration-500" />
              <p className="text-xl font-black uppercase tracking-[0.4em] italic opacity-40 group-hover:opacity-100 transition-opacity">Initiate Tactical Deep Inspection</p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

function HistoryModule({ title, icon: Icon, color, children, emptyText }: any) {
  const [collapsed, setCollapsed] = useState(false);
  const hasChildren = Array.isArray(children) ? (children.find((c: any) => c.props.children && (Array.isArray(c.props.children) ? c.props.children.length > 0 : true)) ? true : false) : !!children;

  return (
    <div className="bg-[#262625] border border-[#4B4A48] rounded shadow-2xl overflow-hidden group/module">
      <button 
        onClick={() => setCollapsed(!collapsed)}
        className="w-full px-8 py-6 flex items-center justify-between bg-[#131313]/50 hover:bg-[#131313] transition-all"
      >
        <div className="flex items-center gap-5">
          <div className={cn("p-2 rounded border border-transparent group-hover/module:border-[#EFD395]/40 transition-all", color)}>
            <Icon size={24} />
          </div>
          <h4 className="font-black text-white tracking-[0.3em] uppercase text-sm italic">{title}</h4>
        </div>
        <div className={cn("h-8 w-8 rounded bg-[#131313] border border-[#4B4A48] flex items-center justify-center text-[#EFD395] transition-transform duration-300", collapsed && "rotate-180")}>
          <ChevronRight size={20} className="rotate-90" />
        </div>
      </button>

      {!collapsed && (
        <div className="p-10 space-y-6 bg-gradient-to-b from-[#131313]/20 to-transparent">
          {children && (Array.isArray(children) ? children.some(c => c) : true) ? children : (
            <div className="py-12 text-center border border-dashed border-[#4B4A48] rounded">
              <p className="text-[#777674] text-[10px] font-black uppercase tracking-[0.4em] italic">{emptyText}</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
