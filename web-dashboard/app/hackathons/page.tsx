'use client';
import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { Trophy, Target, Users, Calendar, MapPin, ExternalLink, Shield, X, Clock, Activity, Hexagon, FileSpreadsheet, Star, Rocket } from 'lucide-react';
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
    <div className="flex flex-col lg:flex-row min-h-screen bg-[#121212] text-[#E0E0E0]">
      <Sidebar />
      
      <main className="flex-1 p-6 md:p-10 mt-16 lg:mt-0">
        <header className="mb-12 flex flex-col md:flex-row justify-between items-start md:items-end border-b border-[#444444] pb-8 gap-6 md:gap-0">
          <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}>
            <h2 className="text-3xl md:text-4xl font-black tracking-tighter text-[#E0E0E0] uppercase italic">Operational Outcomes</h2>
            <p className="text-[#B0B0B0] mt-1 text-[10px] md:text-xs font-bold uppercase tracking-[0.2em] opacity-60">Verified achievements and external benchmarks.</p>
          </motion.div>
          <div className="flex gap-3 w-full md:w-auto">
             <div className="flex-1 md:flex-none px-4 py-3 bg-transparent border border-[#444444] rounded-md flex items-center justify-center gap-3">
                <div className="h-2 w-2 rounded-full bg-[#888888] animate-pulse" />
                <span className="text-[10px] font-black text-[#888888] uppercase tracking-widest">{hackathons.length} Records</span>
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
              className="bg-transparent border border-[#444444] rounded-lg p-6 md:p-8 hover:border-[#888888] transition-all group flex flex-col h-full relative"
            >
              <div className="flex justify-between items-start mb-6">
                <div className="p-2 border border-[#444444] rounded-md text-[#888888]">
                   <Trophy size={20} />
                </div>
                <div className="px-3 py-1 rounded-sm text-[8px] font-black uppercase tracking-[0.2em] border border-[#444444] text-[#888888]">
                  {hack.status}
                </div>
              </div>

              <h3 className="text-xl font-black text-[#E0E0E0] mb-2 uppercase tracking-tight leading-none group-hover:text-white transition-colors">
                {hack.hackName || hack.name}
              </h3>
              <p className="text-[10px] font-black text-[#888888] uppercase tracking-[0.2em] mb-6 truncate">
                Mission: {hack.projectName || hack.teamName || 'Unassigned'}
              </p>

              <div className="space-y-4 flex-1">
                 <div className="flex items-center gap-3 text-[10px] font-bold text-[#B0B0B0] uppercase tracking-wider">
                    <Calendar size={14} className="text-[#444444]" />
                    {new Date(hack.date).toLocaleDateString()}
                 </div>
              </div>

              <div className="pt-6 border-t border-[#444444] mt-8 flex justify-between items-center">
                 <div className="flex -space-x-2 overflow-hidden">
                    {hack.teamMembers?.slice(0, 3).map((member: string, idx: number) => (
                       <div key={idx} className="h-6 w-6 rounded-full bg-[#121212] border border-[#444444] flex items-center justify-center text-[8px] font-black text-[#888888] ring-2 ring-[#121212]" title={member}>
                          {member[0].toUpperCase()}
                       </div>
                    ))}
                    {hack.teamMembers?.length > 3 && (
                       <div className="h-6 w-6 rounded-full bg-[#121212] border border-[#444444] flex items-center justify-center text-[8px] font-black text-[#888888] ring-2 ring-[#121212]">
                          +{hack.teamMembers.length - 3}
                       </div>
                    )}
                 </div>
                 <button 
                  onClick={() => { setSelectedHack(hack); setShowDetails(true); }}
                  className="text-[9px] font-black text-[#E0E0E0] uppercase tracking-widest hover:underline decoration-[#444444] underline-offset-4 transition-all"
                 >
                    Inspect
                 </button>
              </div>
            </motion.div>
          ))}
        </div>

        <AnimatePresence>
          {showDetails && selectedHack && (
            <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-6 bg-black/60 backdrop-blur-sm">
              <motion.div 
                initial={{ opacity: 0, scale: 0.98 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.98 }}
                className="bg-[#121212] border border-[#444444] rounded-lg w-full max-w-2xl max-h-[85vh] overflow-hidden shadow-2xl flex flex-col"
              >
                <div className="p-6 md:p-8 border-b border-[#444444] flex justify-between items-start">
                   <div className="flex gap-4 items-center overflow-hidden">
                      <Trophy size={24} className="text-[#888888] flex-shrink-0" />
                      <div className="overflow-hidden">
                         <p className="text-[10px] font-black text-[#888888] uppercase tracking-[0.3em]">{selectedHack.status}</p>
                         <h2 className="text-lg md:text-2xl font-black text-[#E0E0E0] uppercase tracking-tighter truncate">{selectedHack.hackName || selectedHack.name}</h2>
                      </div>
                   </div>
                   <button onClick={() => setShowDetails(false)} className="p-2 text-[#888888] hover:text-[#E0E0E0] flex-shrink-0">
                      <X size={20} />
                   </button>
                </div>

                <div className="flex-1 overflow-y-auto p-6 md:p-10 space-y-10">
                   <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-8">
                      <div className="p-6 bg-[#444444]/5 border border-[#444444] rounded">
                         <p className="text-[9px] font-black text-[#444444] uppercase tracking-widest mb-2">Chronology</p>
                         <p className="text-sm font-bold text-[#E0E0E0] uppercase">{new Date(selectedHack.date).toDateString()}</p>
                      </div>
                      <div className="p-6 bg-[#444444]/5 border border-[#444444] rounded">
                         <p className="text-[9px] font-black text-[#444444] uppercase tracking-widest mb-2">Impact Result</p>
                         <p className="text-sm font-bold text-[#E0E0E0] uppercase">{selectedHack.result || 'Verified'}</p>
                      </div>
                   </div>

                   <div>
                      <h4 className="text-[9px] font-black text-[#444444] uppercase tracking-[0.3em] mb-4">Briefing</h4>
                      <p className="text-[#B0B0B0] text-sm italic leading-relaxed border-l-2 border-[#444444] pl-4">
                         {selectedHack.description || selectedHack.problemStatement || 'No briefing documented.'}
                      </p>
                   </div>

                   {selectedHack.contribution && (
                      <div>
                         <h4 className="text-[9px] font-black text-[#444444] uppercase tracking-[0.3em] mb-4">Agent Contribution</h4>
                         <p className="text-[#B0B0B0] text-xs leading-relaxed">
                            {selectedHack.contribution}
                         </p>
                      </div>
                   )}

                   <div>
                      <h4 className="text-[9px] font-black text-[#444444] uppercase tracking-[0.3em] mb-4">Deployed Roster</h4>
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                         {selectedHack.teamMembers?.map((member: string, i: number) => (
                            <div key={i} className="flex items-center gap-3 p-3 bg-[#444444]/5 border border-[#444444] rounded truncate">
                               <span className="text-[10px] font-black text-[#E0E0E0] uppercase tracking-tighter truncate">{member}</span>
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
          <div className="p-32 text-center border border-dashed border-[#444444] rounded-lg uppercase font-black text-[10px] tracking-[0.5em] text-[#444444]">
            No Outcomes Documented
          </div>
        )}
      </main>
    </div>
  );
}
