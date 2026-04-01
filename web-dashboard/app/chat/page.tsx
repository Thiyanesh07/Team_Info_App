'use client';
import { useEffect, useState, useRef } from 'react';
import { io, Socket } from 'socket.io-client';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { Send, User, MessageCircle, Clock, ShieldCheck, Search, Paperclip, Smile } from 'lucide-react';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';
import { toast } from 'sonner';

export default function AdminSupportPage() {
  const [conversations, setConversations] = useState<any[]>([]);
  const [activeConv, setActiveConv] = useState<any>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [inputText, setInputText] = useState('');
  const [loading, setLoading] = useState(true);
  const [socket, setSocket] = useState<Socket | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchConversations();
    setupSocket();
    return () => {
      // Clean up socket on unmount
      if (socket) {
        socket.disconnect();
      }
    };
  }, []);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages]);

  const setupSocket = () => {
    const token = localStorage.getItem('admin_token');
    // Standardize URL: Remove /api or any trailing slashes to get the root server URL
    const socketUrl = (process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api').replace('/api', '').replace(/\/$/, '');
    
    const newSocket = io(socketUrl, {
      auth: { token },
      transports: ['websocket'],
      autoConnect: true,
    });

    newSocket.on('connect', () => {
      console.log('Admin Support Socket Connected');
       toast.success('Real-time Relay Established');
    });

    newSocket.on('connect_error', (err) => {
      console.error('Socket Connection error:', err);
    });
    
    newSocket.on('personal_message', (msg) => {
      // Check if this message belongs to the currently active conversation
      if (activeConv && (msg.senderId === activeConv.otherUserId || msg.receiverId === activeConv.otherUserId)) {
        setMessages(prev => [...prev, msg]);
      }
      fetchConversations(); // Refresh list for last message preview & unread indicator logic
    });

    setSocket(newSocket);
  };

  const fetchConversations = async () => {
    try {
      const res = await api.get('/chat/conversations');
      if (res.data.success) {
        setConversations(res.data.data);
      }
    } catch (err) {
      console.error('Fetch conversations error:', err);
    } finally {
      setLoading(false);
    }
  };

  const loadMessages = async (conv: any) => {
    setActiveConv(conv);
    try {
      const res = await api.get(`/chat/personal/${conv.otherUserId}`);
      if (res.data.success) {
        setMessages(res.data.data);
      }
    } catch (err) {
      toast.error('Failed to load transmission history');
    }
  };

  const handleSend = () => {
    if (!inputText.trim() || !activeConv || !socket) return;

    socket.emit('send_personal', {
      receiverId: activeConv.otherUserId,
      message: inputText.trim()
    });

    // For better UX, we could optimistically update local state here if the server echoes back properly.
    // Our backend echoes based on 'personal_message' event handled above.
    setInputText('');
  };

  return (
    <div className="flex h-screen bg-slate-950 text-slate-50 overflow-hidden">
      <Sidebar />
      
      <main className="flex-1 flex flex-col relative">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_0%,rgba(37,99,235,0.05),transparent_50%)] pointer-events-none" />
        
        <header className="h-24 border-b border-white/5 flex items-center justify-between px-8 bg-slate-950/50 backdrop-blur-xl z-10">
          <div>
            <h2 className="text-2xl font-black uppercase tracking-tighter flex items-center gap-3">
              <ShieldCheck className="text-blue-500" />
              Support Center
            </h2>
            <p className="text-[10px] font-black text-slate-500 uppercase tracking-[0.3em] mt-1">Real-time tactical assistance</p>
          </div>
          <div className="flex items-center gap-4">
             <div className="px-4 py-2 bg-emerald-500/10 border border-emerald-500/20 rounded-xl flex items-center gap-2">
                <div className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                <span className="text-[10px] font-black text-emerald-500 uppercase tracking-widest">Relay Active</span>
             </div>
          </div>
        </header>

        <div className="flex-1 flex overflow-hidden">
          {/* Conversation List */}
          <div className="w-80 border-r border-white/5 flex flex-col bg-slate-950/30 backdrop-blur-sm">
            <div className="p-4">
               <div className="relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={14} />
                  <input 
                    type="text" 
                    placeholder="Search Channels..." 
                    className="w-full bg-slate-900/50 border border-slate-800 rounded-xl pl-9 pr-4 py-2.5 text-xs focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition-all font-medium"
                  />
               </div>
            </div>
            
            <div className="flex-1 overflow-y-auto custom-scrollbar">
               {conversations.map(conv => (
                 <button 
                  key={conv.otherUserId}
                  onClick={() => loadMessages(conv)}
                  className={cn(
                    "w-full p-4 flex gap-4 hover:bg-white/5 transition-all text-left group border-l-4",
                    activeConv?.otherUserId === conv.otherUserId ? "bg-blue-600/5 border-blue-500" : "border-transparent"
                  )}
                 >
                   <div className="h-12 w-12 rounded-2xl bg-gradient-to-br from-slate-800 to-slate-900 border border-slate-700 flex items-center justify-center text-slate-400 shrink-0 shadow-lg relative overflow-hidden">
                      {conv.otherUserName?.[0].toUpperCase() || <User size={20} />}
                   </div>
                   <div className="flex-1 min-w-0">
                      <div className="flex justify-between items-start mb-1">
                         <span className="font-bold text-sm text-slate-200 truncate">{conv.otherUserName}</span>
                         <span className="text-[9px] text-slate-500 uppercase font-black">{conv.lastMessageTime?.split('T')[0] || ''}</span>
                      </div>
                      <p className="text-xs text-slate-500 truncate font-medium">{conv.lastMessage || 'No transmissions.'}</p>
                   </div>
                 </button>
               ))}
               
               {conversations.length === 0 && !loading && (
                 <div className="p-12 text-center opacity-20">
                    <MessageCircle size={48} className="mx-auto mb-4" />
                    <p className="text-[10px] font-black uppercase tracking-widest">No support inquiries</p>
                 </div>
               )}
            </div>
          </div>

          {/* Chat Window */}
          <div className="flex-1 flex flex-col relative bg-slate-950/20">
             {activeConv ? (
               <>
                 <div className="flex-1 overflow-y-auto p-8 space-y-6 custom-scrollbar" ref={scrollRef}>
                    {messages.map((m, idx) => {
                      const isMe = m.senderId !== activeConv.otherUserId;
                      return (
                        <div key={m.id || idx} className={cn("flex flex-col animate-in fade-in slide-in-from-bottom-2", isMe ? "items-end" : "items-start")}>
                           <div className={cn(
                             "max-w-[70%] p-4 rounded-3xl text-sm font-medium shadow-2xl relative group",
                             isMe 
                              ? "bg-blue-600 text-white rounded-tr-none" 
                              : "bg-slate-900 border border-white/5 text-slate-200 rounded-tl-none"
                           )}>
                              {m.message}
                              <div className={cn(
                                "absolute bottom-1 right-2 text-[8px] opacity-0 group-hover:opacity-50 transition-opacity flex items-center gap-1",
                                isMe ? "text-white" : "text-slate-500"
                              )}>
                                 <Clock size={8} />
                                 {m.timestamp?.split('T')[1].substring(0, 5)}
                              </div>
                           </div>
                        </div>
                      )
                    })}
                 </div>

                 <div className="p-6 bg-slate-950/50 backdrop-blur-2xl border-t border-white/5">
                    <div className="flex items-center gap-4 bg-slate-900/50 border border-white/10 rounded-3xl p-2 pl-6 focus-within:border-blue-500/50 focus-within:ring-4 focus-within:ring-blue-500/10 transition-all shadow-2xl">
                       <input 
                         type="text" 
                         value={inputText}
                         onChange={e => setInputText(e.target.value)}
                         onKeyPress={e => e.key === 'Enter' && handleSend()}
                         placeholder="Synthesize tactical response..."
                         className="flex-1 bg-transparent py-4 text-sm focus:outline-none placeholder:text-slate-600 font-medium text-white"
                       />
                       <div className="flex items-center gap-1 pr-2">
                          <button className="p-3 text-slate-500 hover:text-blue-400 transition-colors">
                             <Smile size={20} />
                          </button>
                          <button className="p-3 text-slate-500 hover:text-blue-400 transition-colors">
                             <Paperclip size={20} />
                          </button>
                          <button 
                            onClick={handleSend}
                            className="bg-blue-600 hover:bg-blue-500 text-white p-4 rounded-2xl transition-all shadow-lg active:scale-90"
                          >
                             <Send size={18} />
                          </button>
                       </div>
                    </div>
                 </div>
               </>
             ) : (
               <div className="flex-1 flex flex-col items-center justify-center p-20 text-center">
                  <div className="h-32 w-32 rounded-full bg-blue-500/5 border border-blue-500/10 flex items-center justify-center mb-8 relative">
                     <div className="absolute inset-0 bg-blue-500/10 rounded-full blur-2xl animate-pulse" />
                     <MessageCircle size={64} className="text-blue-500/20" />
                  </div>
                  <h3 className="text-4xl font-black text-white uppercase tracking-tighter mb-4">Command Center</h3>
                  <p className="text-slate-500 max-w-sm font-medium leading-relaxed italic">
                    Select a student transmission channel from the left to initiate tactical real-time guidance.
                  </p>
               </div>
             )}
          </div>
        </div>
      </main>
    </div>
  );
}
