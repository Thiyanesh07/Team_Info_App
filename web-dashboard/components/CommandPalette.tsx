'use client';
import { useEffect, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { Search, Users, Rocket, CheckSquare, X, Command } from 'lucide-react';
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
            className="absolute inset-0 bg-slate-950/40 backdrop-blur-md"
          />
          <motion.div 
            initial={{ scale: 0.95, opacity: 0, y: -20 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.95, opacity: 0, y: -20 }}
            className="relative w-full max-w-2xl bg-slate-900 border border-slate-700/50 rounded-3xl shadow-2xl overflow-hidden shadow-blue-500/10"
          >
            <div className="p-6 border-b border-slate-800 flex items-center gap-4">
              <Search className="text-slate-400" size={20} />
              <input 
                ref={inputRef}
                type="text" 
                placeholder="Search Team Hierarchy, Projects, or Assignments..." 
                className="flex-1 bg-transparent border-none text-lg text-white focus:outline-none placeholder:text-slate-600 font-bold"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
              />
              <div className="flex items-center gap-1 px-2 py-1 bg-slate-950 border border-slate-800 rounded-lg text-[10px] font-black text-slate-500 uppercase">
                 <Command size={10} /> K
              </div>
            </div>

            <div className="max-h-[400px] overflow-y-auto p-4 custom-scrollbar">
               {query.length < 3 ? (
                 <div className="p-8 text-center text-slate-500">
                    <p className="text-sm font-bold uppercase tracking-widest opacity-50">Type to bridge the gap</p>
                    <div className="mt-6 flex justify-center gap-6">
                       <QuickLink icon={<Users size={14}/>} label="Members" onClick={() => navigateTo('/members')} />
                       <QuickLink icon={<Rocket size={14}/>} label="Projects" onClick={() => navigateTo('/projects')} />
                       <QuickLink icon={<CheckSquare size={14}/>} label="Tasks" onClick={() => navigateTo('/tasks')} />
                    </div>
                 </div>
               ) : (
                 <div className="space-y-6 p-2">
                    {/* Users Section */}
                    {results.users.length > 0 && (
                      <SearchSection title="Accounts" icon={<Users size={12}/>}>
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
                      <SearchSection title="Directives" icon={<Rocket size={12}/>}>
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
                      <div className="p-12 text-center text-slate-600">
                         <p className="font-bold uppercase tracking-widest text-xs">No administrative matches</p>
                      </div>
                    )}
                 </div>
               )}
            </div>

            <div className="p-4 bg-slate-950/50 border-t border-slate-800 flex justify-between items-center text-[10px] font-black text-slate-500 uppercase tracking-widest">
               <div className="flex gap-4">
                  <span>ESC to exit</span>
                  <span>ENTER to select</span>
               </div>
               <span className="text-blue-500">Intelligent Search Core</span>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}

function SearchSection({ title, icon, children }: any) {
  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2 px-2">
         {icon}
         <span className="text-[10px] font-black uppercase tracking-widest text-slate-500">{title}</span>
      </div>
      <div className="space-y-1">
        {children}
      </div>
    </div>
  );
}

function SearchResult({ title, subtitle, onClick }: any) {
  return (
    <button 
      onClick={onClick}
      className="w-full text-left p-3 rounded-2xl hover:bg-blue-600/10 hover:border-blue-500/20 border border-transparent transition-all group flex items-center justify-between"
    >
      <div>
        <p className="text-sm font-bold text-slate-200 group-hover:text-blue-400 transition-colors uppercase tracking-tight">{title}</p>
        <p className="text-[10px] text-slate-500 font-medium group-hover:text-slate-400">{subtitle}</p>
      </div>
      <div className="h-6 w-6 rounded-lg bg-slate-950 border border-slate-800 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
         <X size={10} className="rotate-45 text-blue-500" />
      </div>
    </button>
  );
}

function QuickLink({ icon, label, onClick }: any) {
  return (
    <button onClick={onClick} className="flex flex-col items-center gap-2 group">
       <div className="h-10 w-10 rounded-2xl bg-slate-950 border border-slate-800 flex items-center justify-center text-slate-400 group-hover:text-blue-500 group-hover:border-blue-500/30 transition-all">
          {icon}
       </div>
       <span className="text-[8px] font-black uppercase tracking-widest text-slate-600 group-hover:text-slate-400">{label}</span>
    </button>
  );
}
