'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { Trophy, Target, Users, Calendar, MapPin, ExternalLink, Shield, X, Clock, Activity, Hexagon, FileSpreadsheet, Star, Rocket, ChevronRight } from 'lucide-react';
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

  return (
    <div className="flex flex-col lg:flex-row min-h-screen bg-[#131313] text-[#FFFFFF]">
      <Sidebar />
      
      <main className="flex-1 p-6 md:p-10 mt-16 lg:mt-0 custom-scrollbar no-scrollbar">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-[#4B4A48] pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl md:text-5xl font-black tracking-tighter text-[#FFFFFF] uppercase italic">Operational Outcomes</h2>
            <p className="text-[#A4A4A4] mt-1 text-[10px] md:text-xs font-black uppercase tracking-[0.2em] opacity-60">Verified achievements and external benchmarks.</p>
          </motion.div>
          <div className="flex gap-3 w-full md:w-auto">
             <div className="flex-1 md:flex-none px-6 py-3 bg-transparent border border-[#4B4A48] rounded flex items-center justify-center gap-4 group">
                <div className="h-2 w-2 rounded-full bg-[#EFD395] animate-pulse shadow-[0_0_8px_rgba(239,211,149,0.5)]" />
                <span className="text-[10px] font-black text-[#A4A4A4] group-hover:text-[#EFD395] transition-colors uppercase tracking-[0.3em]">{hackathons.length} Records</span>
             </div>
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6 md:gap-8">
          {hackathons.map((hack, i) => (
            <motion.div 
              key={hack.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="bg-[#262625] border border-[#4B4A48] rounded p-8 hover:border-[#EFD395]/30 transition-all group flex flex-col h-full relative"
            >
              <div className="flex justify-between items-start mb-8">
                <div className="p-2.5 border border-[#4B4A48] rounded text-[#EFD395] bg-[#131313] shadow-inner">
                   <Trophy size={20} />
                </div>
                <div className="px-3 py-1 rounded text-[8px] font-black uppercase tracking-[0.2em] border border-[#4B4A48] text-[#777674] bg-[#131313]">
                  {hack.status}
                </div>
              </div>

              <h3 className="text-xl md:text-2xl font-black text-[#FFFFFF] mb-2 uppercase tracking-tight leading-none group-hover:text-[#EFD395] transition-colors italic">
                {hack.hackName || hack.name}
              </h3>
              <p className="text-[10px] font-black text-[#EFD395]/60 uppercase tracking-[0.2em] mb-8 truncate italic">
                Mission: {hack.projectName || hack.teamName || 'Unassigned'}
              </p>

              <div className="space-y-4 flex-1">
                 <div className="flex items-center gap-3 text-[10px] font-black text-[#A4A4A4] uppercase tracking-widest italic">
                    <Calendar size={14} className="text-[#4B4A48] group-hover:text-[#EFD395] transition-colors" />
                    {new Date(hack.date).toLocaleDateString()}
                 </div>
              </div>

              <div className="pt-8 border-t border-[#4B4A48] mt-10 flex justify-between items-center bg-[#131313]/10 -mx-8 px-8 -mb-8 pb-8 rounded-b">
                 <div className="flex -space-x-2 overflow-hidden">
                    {hack.teamMembers?.slice(0, 3).map((member: string, idx: number) => (
                       <div key={idx} className="h-7 w-7 rounded bg-[#262625] border border-[#4B4A48] flex items-center justify-center text-[9px] font-black text-[#A4A4A4] ring-2 ring-[#262625] group-hover:border-[#EFD395]/40 transition-colors" title={member}>
                          {member[0].toUpperCase()}
                       </div>
                    ))}
                    {hack.teamMembers?.length > 3 && (
                       <div className="h-7 w-7 rounded bg-[#262625] border border-[#4B4A48] flex items-center justify-center text-[9px] font-black text-[#EFD395] ring-2 ring-[#262625]">
                          +{hack.teamMembers.length - 3}
                       </div>
                    )}
                 </div>
                 <button 
                  onClick={() => { setSelectedHack(hack); setShowDetails(true); }}
                  className="text-[9px] font-black text-[#FFFFFF] uppercase tracking-[0.3em] hover:text-[#EFD395] transition-all flex items-center gap-2 group/btn"
                 >
                    Inspect <ChevronRight size={12} className="group-hover/btn:translate-x-1 transition-transform" />
                 </button>
              </div>
            </motion.div>
          ))}
        </div>

        <AnimatePresence>
          {showDetails && selectedHack && (
            <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-black/80 backdrop-blur-md">
              <motion.div 
                initial={{ opacity: 0, scale: 0.98 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.98 }}
                className="bg-[#262625] border border-[#4B4A48] rounded w-full max-w-2xl max-h-[90vh] overflow-hidden shadow-2xl flex flex-col"
              >
                <div className="p-8 md:p-10 border-b border-[#4B4A48] flex justify-between items-start bg-[#131313]/30">
                   <div className="flex gap-4 items-center overflow-hidden">
                      <div className="p-3 bg-[#131313] border border-[#4B4A48] rounded text-[#EFD395]">
                        <Trophy size={28} className="flex-shrink-0" />
                      </div>
                      <div className="overflow-hidden">
                         <p className="text-[10px] font-black text-[#EFD395] uppercase tracking-[0.4em] mb-1 italic">{selectedHack.status}</p>
                         <h2 className="text-lg md:text-3xl font-black text-[#FFFFFF] uppercase tracking-tighter truncate italic">{selectedHack.hackName || selectedHack.name}</h2>
                      </div>
                   </div>
                   <button onClick={() => setShowDetails(false)} className="p-2 text-[#777674] hover:text-[#FFFFFF] flex-shrink-0 transition-colors">
                      <X size={28} />
                   </button>
                </div>

                <div className="flex-1 overflow-y-auto p-8 md:p-12 space-y-12 custom-scrollbar no-scrollbar">
                   <div className="grid grid-cols-1 md:grid-cols-2 gap-6 md:gap-10">
                      <div className="p-6 bg-[#131313] border border-[#4B4A48] rounded shadow-inner">
                         <p className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] mb-3 flex items-center gap-2">
                           <Clock size={12} className="text-[#EFD395]" /> Chronology
                         </p>
                         <p className="text-sm font-black text-[#FFFFFF] uppercase italic tracking-widest">{new Date(selectedHack.date).toDateString()}</p>
                      </div>
                      <div className="p-6 bg-[#131313] border border-[#4B4A48] rounded shadow-inner">
                         <p className="text-[10px] font-black text-[#777674] uppercase tracking-[0.3em] mb-3 flex items-center gap-2">
                           <Target size={12} className="text-[#EFD395]" /> Impact Result
                         </p>
                         <p className="text-sm font-black text-[#EFD395] uppercase italic tracking-widest">{selectedHack.result || 'Verified Operation'}</p>
                      </div>
                   </div>

                   <div>
                      <h4 className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.4em] mb-6 flex items-center gap-2">
                        <Activity size={14} className="text-[#EFD395]" /> Operational Briefing
                      </h4>
                      <p className="text-[#A4A4A4] text-sm italic leading-relaxed border-l-2 border-[#EFD395] pl-8 py-2 bg-[#131313]/20 rounded-r pr-6">
                         {selectedHack.description || selectedHack.problemStatement || 'No briefing documented.'}
                      </p>
                   </div>

                   {selectedHack.contribution && (
                      <div>
                         <h4 className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.4em] mb-6 flex items-center gap-2">
                           <Hexagon size={14} className="text-[#EFD395]" /> Agent Contribution
                         </h4>
                         <p className="text-[#A4A4A4] text-xs leading-relaxed italic border-l-2 border-[#4B4A48] pl-8">
                            {selectedHack.contribution}
                         </p>
                      </div>
                   )}

                   <div>
                      <h4 className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.4em] mb-6 flex items-center gap-2">
                        <Users size={14} className="text-[#EFD395]" /> Deployed Roster
                      </h4>
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                         {selectedHack.teamMembers?.map((member: string, i: number) => (
                            <div key={i} className="flex items-center justify-between p-4 bg-[#131313] border border-[#4B4A48] rounded truncate hover:border-[#EFD395]/40 transition-colors group">
                               <div className="flex items-center gap-4 overflow-hidden">
                                  <div className="h-1.5 w-1.5 rounded-full bg-[#EFD395]" />
                                  <span className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.2em] truncate italic transition-colors group-hover:text-[#FFFFFF]">{member}</span>
                               </div>
                               <Shield size={12} className="text-[#4B4A48] group-hover:text-[#EFD395]/60 transition-colors" />
                            </div>
                         ))}
                      </div>
                   </div>
                </div>
              </motion.div>
            </div>
          )}
        </AnimatePresence>

        {!loading && hackathons.length === 0 && (
          <div className="p-32 text-center border border-dashed border-[#4B4A48] rounded group">
            <p className="text-[10px] font-black text-[#777674] uppercase tracking-[0.5em] italic group-hover:text-[#EFD395] transition-colors">No Outcomes Documented</p>
          </div>
        )}
      </main>
    </div>
  );
}
