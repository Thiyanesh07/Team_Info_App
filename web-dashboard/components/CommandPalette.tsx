'use client';
import { useEffect, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { Search, Users, Rocket, CheckSquare, X, Command, ChevronRight } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { cn } from '@/lib/utils';

export default function CommandPalette() {
  const [isOpen, setIsOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [results, setResults] = useState({
    users: [],
    projects: [],
    tasks: []
  });
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setIsOpen((prev) => !prev);
      }
      if (e.key === 'Escape') setIsOpen(false);
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  useEffect(() => {
    if (isOpen) {
      inputRef.current?.focus();
      if (query.length > 2) {
        performSearch();
      }
    }
  }, [isOpen, query]);

  const performSearch = async () => {
    setLoading(true);
    try {
      // In a real scenario, we'd have a unified search endpoint
      // For now, we'll fetch basic lists and filter client-side or use existing endpoints
      const [uRes, pRes, tRes] = await Promise.all([
        api.get('/users'),
        api.get('/projects').catch(() => ({ data: { success: true, data: [] } })),
        api.get('/tasks/all').catch(() => ({ data: { success: true, data: [] } }))
      ]);

      const q = query.toLowerCase();
      setResults({
        users: uRes.data.data?.filter((u: any) => u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q)).slice(0, 3) || [],
        projects: pRes.data.data?.filter((p: any) => p.title.toLowerCase().includes(q)).slice(0, 3) || [],
        tasks: tRes.data.data?.filter((t: any) => t.title.toLowerCase().includes(q)).slice(0, 3) || []
      });
    } catch (err) {
      console.error('Search error:', err);
    } finally {
      setLoading(false);
    }
  };

  const navigateTo = (path: string) => {
    router.push(path);
    setIsOpen(false);
    setQuery('');
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-[100] flex items-start justify-center pt-24 p-6 sm:p-0">
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setIsOpen(false)}
            className="absolute inset-0 bg-black/80 backdrop-blur-md"
          />
          <motion.div 
            initial={{ scale: 0.95, opacity: 0, y: -20 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.95, opacity: 0, y: -20 }}
            className="relative w-full max-w-2xl bg-[#262625] border border-[#4B4A48] rounded shadow-2xl overflow-hidden shadow-black/80"
          >
            <div className="p-8 border-b border-[#4B4A48] flex items-center gap-6 bg-[#131313]/30">
              <Search className="text-[#EFD395]" size={24} />
              <input 
                ref={inputRef}
                type="text" 
                placeholder="Search Team Hierarchy, Projects, or Assignments..." 
                className="flex-1 bg-transparent border-none text-xl text-white focus:outline-none placeholder:text-[#4B4A48] font-black uppercase italic tracking-tighter"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
              />
              <div className="flex items-center gap-2 px-3 py-1.5 bg-[#131313] border border-[#4B4A48] rounded text-[10px] font-black text-[#A4A4A4] uppercase italic shadow-inner">
                 <Command size={12} className="text-[#EFD395]" /> K
              </div>
            </div>

            <div className="max-h-[450px] overflow-y-auto p-6 custom-scrollbar no-scrollbar">
               {query.length < 3 ? (
                 <div className="p-12 text-center">
                    <p className="text-[10px] font-black uppercase tracking-[0.5em] text-[#777674] italic opacity-60">Type to bridge the tactical gap</p>
                    <div className="mt-10 flex justify-center gap-8">
                       <QuickLink icon={<Users size={16}/>} label="Members" onClick={() => navigateTo('/members')} />
                       <QuickLink icon={<Rocket size={16}/>} label="Projects" onClick={() => navigateTo('/projects')} />
                       <QuickLink icon={<CheckSquare size={16}/>} label="Tasks" onClick={() => navigateTo('/tasks')} />
                    </div>
                 </div>
               ) : (
                 <div className="space-y-8 p-2">
                    {/* Users Section */}
                    {results.users.length > 0 && (
                      <SearchSection title="Accounts" icon={<Users size={14}/>}>
                        {results.users.map((u: any) => (
                           <SearchResult 
                            key={u.id} 
                            title={u.name} 
                            subtitle={u.email} 
                            onClick={() => navigateTo(`/inspection?search=${u.name}`)}
                           />
                        ))}
                      </SearchSection>
                    )}

                    {/* Projects Section */}
                    {results.projects.length > 0 && (
                      <SearchSection title="Directives" icon={<Rocket size={14}/>}>
                        {results.projects.map((p: any) => (
                           <SearchResult 
                            key={p.id} 
                            title={p.title} 
                            subtitle={`Status: ${p.status}`} 
                            onClick={() => navigateTo('/projects')}
                           />
                        ))}
                      </SearchSection>
                    )}

                    {!loading && results.users.length === 0 && results.projects.length === 0 && (
                      <div className="p-20 text-center border border-dashed border-[#4B4A48] rounded group">
                         <p className="font-black uppercase tracking-[0.4em] text-[10px] text-[#777674] italic group-hover:text-[#EFD395] transition-colors">No administrative matches</p>
                      </div>
                    )}
                 </div>
               )}
            </div>

            <div className="p-5 bg-[#131313] border-t border-[#4B4A48] flex justify-between items-center text-[9px] font-black text-[#777674] uppercase tracking-[0.3em] italic">
               <div className="flex gap-6">
                  <span className="flex items-center gap-2 px-3 py-1 bg-[#262625] rounded shadow-inner">ESC <span className="opacity-40">EXIT</span></span>
                  <span className="flex items-center gap-2 px-3 py-1 bg-[#262625] rounded shadow-inner">ENTER <span className="opacity-40">SELECT</span></span>
               </div>
               <span className="text-[#EFD395] opacity-60">Intelligent Search Core</span>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}

function SearchSection({ title, icon, children }: any) {
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3 px-2">
         <div className="p-1.5 bg-[#131313] border border-[#4B4A48] rounded text-[#EFD395]">
            {icon}
         </div>
         <span className="text-[10px] font-black uppercase tracking-[0.4em] text-[#A4A4A4] italic">{title}</span>
      </div>
      <div className="space-y-2">
        {children}
      </div>
    </div>
  );
}

function SearchResult({ title, subtitle, onClick }: any) {
  return (
    <button 
      onClick={onClick}
      className="w-full text-left p-4 rounded bg-[#131313]/40 hover:bg-[#131313] border border-[#4B4A48]/30 hover:border-[#EFD395]/40 transition-all group flex items-center justify-between"
    >
      <div>
        <p className="text-sm font-black text-white group-hover:text-[#EFD395] transition-colors uppercase italic tracking-tight">{title}</p>
        <p className="text-[10px] text-[#777674] font-black uppercase italic tracking-widest mt-1 opacity-60">{subtitle}</p>
      </div>
      <div className="h-8 w-8 rounded bg-[#262625] border border-[#4B4A48] flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity shadow-inner">
         <ChevronRight size={14} className="text-[#EFD395]" />
      </div>
    </button>
  );
}

function QuickLink({ icon, label, onClick }: any) {
  return (
    <button onClick={onClick} className="flex flex-col items-center gap-3 group">
       <div className="h-14 w-14 rounded bg-[#131313] border border-[#4B4A48] flex items-center justify-center text-[#A4A4A4] group-hover:text-[#EFD395] group-hover:border-[#EFD395] transition-all shadow-inner group-hover:scale-110 duration-300">
          {icon}
       </div>
       <span className="text-[9px] font-black uppercase tracking-[0.3em] text-[#777674] group-hover:text-white transition-colors italic">{label}</span>
    </button>
  );
}
