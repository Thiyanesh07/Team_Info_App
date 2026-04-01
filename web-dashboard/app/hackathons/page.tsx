'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api, { downloadExcel } from '@/lib/api';
import { Trophy, Target, Users, Calendar, ExternalLink, Shield, X, Clock, Activity, Hexagon, FileSpreadsheet, Star } from 'lucide-react';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';
import { toast } from 'sonner';

export default function HackathonsPage() {
  const [hackathons, setHackathons] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedHack, setSelectedHack] = useState<any>(null);
  const [showDetails, setShowDetails] = useState(false);

  useEffect(() => {
    fetchHackathons();
  }, []);

  const fetchHackathons = async () => {
    try {
      const res = await api.get('/hackathons');
      if (res.data.success) {
        setHackathons(res.data.data);
      }
    } catch (err) {
      console.error('Fetch hackathons error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async () => {
    try {
      toast.info('Generating Hackathon Report...');
      await downloadExcel('/export/hackathons', `Team_Hackathons_${new Date().getTime()}.xlsx`, { scope: 'TEAM' });
      toast.success('Hackathon Report Downloaded');
    } catch (err: any) {
      toast.error('Export Failed');
    }
  };

  // Mock data if empty for demo
  const mockHacks = [
    {
      id: 'h1',
      name: 'Global AI Summit 2024',
      status: 'ONGOING',
      teamName: 'Neural Knights',
      problemStatement: 'Building resilient AI agents for disaster management using localized LLMs.',
      domain: 'AI & ML',
      members: [{ user: { name: 'Thiyanesh' } }, { user: { name: 'Alex' } }],
      achievements: 'Pending Results'
    },
    {
      id: 'h2',
      name: 'Smart India Hackathon',
      status: 'COMPLETED',
      teamName: 'Antigravity',
      problemStatement: 'Devised a decentralized supply chain for medical oxygen tracking.',
      domain: 'Blockchain',
      members: [{ user: { name: 'Sarah' } }],
      achievements: 'Finalists'
    }
  ];

  const displayHacks = hackathons.length > 0 ? hackathons : mockHacks;

  return (
    <div className="flex min-h-screen bg-slate-950 text-slate-50">
      <Sidebar />
      
      <main className="flex-1 p-8">
        <header className="mb-10 flex justify-between items-end">
          <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl font-black tracking-tight text-white uppercase tracking-tighter">Hackathon Arena</h2>
            <p className="text-slate-400 mt-1 font-medium italic">Tracking competitive team deployments and tactical victories.</p>
          </motion.div>
          <div className="flex gap-4 items-center">
            <button 
              onClick={handleExport}
              className="px-6 py-3 bg-slate-900 border border-slate-700 hover:border-emerald-500/50 hover:bg-emerald-500/5 text-slate-300 hover:text-emerald-400 rounded-2xl text-[10px] font-black uppercase tracking-widest transition-all shadow-xl active:scale-95 group flex items-center gap-2"
            >
              <FileSpreadsheet size={16} className="group-hover:animate-pulse" />
              Export Hackathons
            </button>
            <div className="px-4 py-3 bg-slate-900 border border-slate-800 rounded-2xl flex items-center gap-3">
              <div className="h-2 w-2 rounded-full bg-amber-500 animate-pulse" />
              <span className="text-[10px] font-black text-slate-300 uppercase tracking-widest">{displayHacks.length} Arenas Active</span>
            </div>
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {displayHacks.map((hack, i) => (
            <motion.div 
              key={hack.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className="bg-slate-900 border border-slate-800 rounded-[2.5rem] p-8 hover:border-blue-500/30 transition-all group flex flex-col h-full relative overflow-hidden shadow-2xl"
            >
              <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:opacity-10 transition-opacity">
                 <Trophy size={80} className={cn(hack.status === 'WINNER' ? 'text-amber-500' : 'text-slate-400')} />
              </div>

              <div className="flex justify-between items-start mb-6">
                <div className={cn(
                  "p-4 rounded-[1.25rem] border shadow-lg",
                  hack.status === 'WINNER' ? "bg-amber-500/10 border-amber-500/20 text-amber-500 shadow-amber-500/10" :
                  hack.status === 'COMPLETED' ? "bg-emerald-500/10 border-emerald-500/20 text-emerald-500 shadow-emerald-500/10" :
                  hack.status === 'PARTICIPATED' ? "bg-purple-500/10 border-purple-500/20 text-purple-500 shadow-purple-500/10" :
                  hack.status === 'ONGOING' ? "bg-blue-500/10 border-blue-500/20 text-blue-500 shadow-blue-500/10" :
                  "bg-slate-500/10 border-slate-500/20 text-slate-500"
                )}>
                  {hack.status === 'WINNER' ? <Star size={24} /> : <Trophy size={24} />}
                </div>
                <div className={cn(
                  "px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-[0.2em] border backdrop-blur-md",
                  hack.status === 'WINNER' ? "bg-amber-500/10 text-amber-500 border-amber-500/20" :
                  hack.status === 'COMPLETED' ? "bg-emerald-500/10 text-emerald-500 border-emerald-500/20" :
                  hack.status === 'PARTICIPATED' ? "bg-purple-500/10 text-purple-500 border-purple-500/20" :
                  hack.status === 'ONGOING' ? "bg-blue-500/10 text-blue-500 border-blue-500/20" :
                  "bg-slate-500/10 text-slate-500 border-slate-500/20"
                )}>
                  {hack.status}
                </div>
              </div>

              <h3 className="text-2xl font-black text-white mb-2 group-hover:text-blue-400 transition-colors uppercase tracking-tight leading-none">
                {hack.hackName || hack.name}
              </h3>
              <p className="text-xs text-blue-500 font-bold uppercase tracking-widest mb-1">Mission: {hack.projectName || hack.teamName}</p>
              
              <div className="flex flex-wrap gap-2 mb-4">
                {(hack.skillsUsed || []).map((skill: string) => (
                  <span key={skill} className="px-2 py-0.5 bg-slate-800 border border-slate-700/50 rounded-md text-[8px] font-black text-slate-400 uppercase tracking-tighter">
                    {skill}
                  </span>
                ))}
              </div>

              <p className="text-sm text-slate-400 line-clamp-2 mb-8 flex-1 italic leading-relaxed font-medium">
                "{hack.description || hack.problemStatement || 'No mission briefing defined.'}"
              </p>

              <div className="pt-8 border-t border-slate-800/50 space-y-4">
                {hack.contribution && (
                   <div className="bg-slate-950/50 p-4 rounded-2xl border border-slate-800/50">
                      <p className="text-[10px] text-slate-500 font-black uppercase tracking-widest mb-1.5 opacity-50">Impact Contribution</p>
                      <p className="text-xs text-slate-300 font-medium leading-relaxed italic">{hack.contribution}</p>
                   </div>
                )}

                <div className="flex items-center justify-between">
                  <span className="text-[10px] text-slate-500 flex items-center gap-2 font-black uppercase tracking-widest">
                    <Users size={14} className="text-slate-400" /> Active Agents
                  </span>
                  <div className="flex -space-x-2">
                    {(hack.teamMembers || []).map((member: string, idx: number) => (
                       <div key={idx} className="w-8 h-8 rounded-full bg-slate-800 border-2 border-slate-900 flex items-center justify-center text-[10px] font-black text-slate-400 ring-2 ring-slate-800/50" title={member}>
                          {member[0].toUpperCase()}
                       </div>
                    ))}
                    {(!hack.teamMembers || hack.teamMembers.length === 0) && (
                      <span className="text-xs font-bold text-white">{hack.isTeam ? 'Squad Operation' : 'Solo Op'}</span>
                    )}
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {displayHacks.length === 0 && !loading && (
          <div className="p-32 text-center text-slate-500 border-2 border-dashed border-slate-800 rounded-[3rem]">
            <Trophy size={48} className="mx-auto mb-4 opacity-10" />
            <p className="font-bold text-lg uppercase tracking-widest text-slate-300">Tactical Silence</p>
            <p className="text-sm mt-1">No competitive engagements registered in the mainframe.</p>
          </div>
        )}
      </main>
    </div>
  );
}
