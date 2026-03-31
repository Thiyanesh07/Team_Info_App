'use client';
import { useState, useEffect } from 'react';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { Search, UserCircle, Calendar, Briefcase, GraduationCap, Zap, Activity } from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';

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
    <div className="flex min-h-screen bg-slate-950 text-slate-50">
      <Sidebar />
      
      <main className="flex-1 p-8 overflow-y-auto">
        <header className="mb-10">
          <h2 className="text-3xl font-bold tracking-tight">Performance Inspection</h2>
          <p className="text-slate-400 mt-1">Deep-dive into team member history and accountability</p>
        </header>

        <div className="max-w-4xl mx-auto space-y-8">
          {/* Search Bar */}
          <div className="relative group">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 group-focus-within:text-blue-500 transition-colors" />
            <input 
              type="text" 
              placeholder="Search by name or email to inspect..." 
              className="w-full bg-slate-900 border border-slate-800 rounded-2xl pl-12 pr-4 py-4 text-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-2xl"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            
            {/* Search Results Dropdown */}
            {searchQuery.length > 2 && users.length > 0 && !selectedUser && (
              <div className="absolute top-full left-0 right-0 mt-2 bg-slate-900 border border-slate-800 rounded-xl shadow-2xl z-50 overflow-hidden divide-y divide-slate-800">
                {users.map(user => (
                  <button 
                    key={user.id}
                    onClick={() => {
                      fetchUserDetail(user.id);
                      setSearchQuery('');
                    }}
                    className="w-full text-left p-4 hover:bg-slate-800 flex items-center gap-4 transition-colors"
                  >
                    <div className="h-10 w-10 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center font-bold text-slate-400">
                      {user.profileImageUrl ? (
                        <img src={user.profileImageUrl} alt="" className="w-full h-full rounded-full object-cover" />
                      ) : (
                        user.name[0]
                      )}
                    </div>
                    <div>
                      <p className="font-bold">{user.name}</p>
                      <p className="text-xs text-slate-500">{user.email} • {user.role}</p>
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>

          {loading && (
            <div className="text-center py-20">
              <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500 mx-auto"></div>
              <p className="text-slate-500 mt-4 font-medium italic">Scanning historical records...</p>
            </div>
          )}

          {userDetail && selectedUser && !loading && (
            <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
              {/* User Profiler Header */}
              <div className="bg-slate-900 border border-slate-800 p-8 rounded-3xl flex flex-col md:flex-row items-center gap-6 shadow-xl relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-blue-600/5 blur-3xl -mr-16 -mt-16"></div>
                <div className="h-24 w-24 rounded-full bg-slate-800 border-2 border-blue-500/30 flex-shrink-0 flex items-center justify-center text-4xl font-bold text-blue-400">
                  {selectedUser.profileImageUrl ? (
                    <img src={selectedUser.profileImageUrl} alt="" className="w-full h-full rounded-full object-cover" />
                  ) : (
                    selectedUser.name[0]
                  )}
                </div>
                <div className="flex-1 text-center md:text-left">
                  <h3 className="text-3xl font-extrabold tracking-tight">{selectedUser.name}</h3>
                  <div className="flex flex-wrap justify-center md:justify-start gap-3 mt-2">
                    <span className="px-3 py-1 bg-blue-500/10 text-blue-400 rounded-full text-xs font-bold border border-blue-500/20">{selectedUser.role}</span>
                    <span className="px-3 py-1 bg-emerald-500/10 text-emerald-400 rounded-full text-xs font-bold border border-emerald-500/20">{selectedUser.department || 'General'}</span>
                    <span className="px-3 py-1 bg-slate-800 text-slate-400 rounded-full text-xs font-bold border border-slate-700">{selectedUser.email}</span>
                  </div>
                </div>
              </div>

              {/* History Modules */}
              <div className="grid grid-cols-1 gap-6">
                {/* 1. Project Updates */}
                <HistoryModule 
                  title="Project Footprint" 
                  icon={Briefcase} 
                  color="text-emerald-400"
                  emptyText="No recorded project contributions yet."
                >
                  {userDetail.projectUpdates?.map((up: any) => (
                    <div key={up.id} className="p-4 bg-slate-950/50 rounded-xl border border-slate-800">
                      <div className="flex justify-between items-start mb-2">
                        <h5 className="font-bold text-slate-200">{up.title}</h5>
                        <time className="text-[10px] text-slate-500 font-bold uppercase">{format(new Date(up.date), 'MMM dd, yyyy')}</time>
                      </div>
                      <p className="text-sm text-slate-400 leading-relaxed">{up.description}</p>
                      <div className="mt-2 flex items-center gap-2">
                        <span className="text-[10px] font-bold text-blue-500 bg-blue-500/5 px-2 py-0.5 rounded border border-blue-500/10">Project: {up.project?.projectName}</span>
                      </div>
                    </div>
                  ))}
                </HistoryModule>

                {/* 2. Tasks */}
                <HistoryModule 
                  title="Operational Accountability" 
                  icon={Zap} 
                  color="text-orange-400"
                  emptyText="No tasks assigned to this user."
                >
                  {userDetail.tasksReceived?.map((t: any) => (
                    <div key={t.id} className="p-4 bg-slate-950/50 rounded-xl border border-slate-800 flex justify-between items-center">
                      <div>
                        <h5 className="font-bold text-slate-200">{t.title}</h5>
                        <p className="text-xs text-slate-500 italic mt-1">Assigned By: {t.assignedBy?.name}</p>
                      </div>
                      <span className={cn(
                        "px-2 px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wide border",
                        t.status === 'COMPLETED' ? "bg-emerald-500/10 text-emerald-500 border-emerald-500/20" : 
                        "bg-orange-500/10 text-orange-500 border-orange-500/20"
                      )}>
                        {t.status.replace('_', ' ')}
                      </span>
                    </div>
                  ))}
                </HistoryModule>

                {/* 3. Learning Path */}
                <HistoryModule 
                  title="Skill Intelligence" 
                  icon={GraduationCap} 
                  color="text-purple-400"
                  emptyText="No registered learning activities."
                >
                   {userDetail.learnings?.map((l: any) => (
                    <div key={l.id} className="p-4 bg-slate-950/50 rounded-xl border border-slate-800 flex items-center justify-between">
                      <div>
                        <h5 className="font-bold text-slate-200">{l.skillName}</h5>
                        <p className="text-xs text-slate-500">{l.startDate && format(new Date(l.startDate), 'MMM yyyy')} - {l.endDate ? format(new Date(l.endDate), 'MMM yyyy') : 'Present'}</p>
                      </div>
                      <span className="bg-slate-800 px-3 py-1 rounded-lg text-xs font-bold text-slate-400 border border-slate-700">{l.level}</span>
                    </div>
                  ))}
                </HistoryModule>
              </div>
            </div>
          )}

          {!selectedUser && !loading && (
            <div className="py-20 text-center text-slate-500">
              <UserCircle size={64} className="mx-auto opacity-10 mb-6" />
              <p className="text-lg font-medium italic">Search for a team member to initiate deep inspection</p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

function HistoryModule({ title, icon: Icon, color, children, emptyText }: any) {
  const [collapsed, setCollapsed] = useState(false);
  const hasChildren = Array.isArray(children) ? children.length > 0 : !!children;

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-lg">
      <button 
        onClick={() => setCollapsed(!collapsed)}
        className="w-full px-6 py-4 flex items-center justify-between bg-slate-900/50 hover:bg-slate-800/80 transition-colors"
      >
        <div className="flex items-center gap-3">
          <Icon className={color} size={20} />
          <h4 className="font-bold text-slate-200 tracking-wide uppercase text-sm">{title}</h4>
        </div>
        <span className="text-slate-500">{collapsed ? '+' : '−'}</span>
      </button>

      {!collapsed && (
        <div className="p-6 space-y-4">
          {hasChildren ? children : (
            <p className="text-center py-6 text-slate-600 text-sm italic">{emptyText}</p>
          )}
        </div>
      )}
    </div>
  );
}
