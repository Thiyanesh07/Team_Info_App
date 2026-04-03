'use client';
import { useEffect, useState, useRef } from 'react';
import { io, Socket } from 'socket.io-client';
import Sidebar from '@/components/Sidebar';
import api from '@/lib/api';
import { Send, User, MessageCircle, Clock, ShieldCheck, Search, Paperclip, Smile, ChevronRight } from 'lucide-react';
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
    <div className="flex h-screen bg-[#131313] text-[#FFFFFF] overflow-hidden">
      <Sidebar />
      
      <main className="flex-1 flex flex-col relative mt-16 lg:mt-0">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_0%,rgba(239,211,149,0.03),transparent_60%)] pointer-events-none" />
        
        <header className="h-28 border-b border-[#4B4A48] flex items-center justify-between px-10 bg-[#131313]/80 backdrop-blur-3xl z-10">
          <div>
            <h2 className="text-3xl md:text-4xl font-black tracking-tighter text-[#FFFFFF] uppercase italic flex items-center gap-4">
              <ShieldCheck className="text-[#EFD395]" size={32} />
              Support Center
            </h2>
            <p className="text-[10px] font-black text-[#A4A4A4] uppercase tracking-[0.4em] mt-1 opacity-60 italic">Global operational assistance protocol.</p>
          </div>
          <div className="flex items-center gap-4">
             <div className="px-6 py-2.5 bg-[#131313] border border-[#4B4A48] rounded flex items-center gap-3 shadow-inner group">
                <div className="h-2 w-2 rounded-full bg-[#EFD395] animate-pulse shadow-[0_0_8px_rgba(239,211,149,0.5)]" />
                <span className="text-[10px] font-black text-[#EFD395] uppercase tracking-[0.3em] italic">Relay Active</span>
             </div>
          </div>
        </header>

        <div className="flex-1 flex overflow-hidden">
          {/* Conversation List */}
          <div className="w-96 border-r border-[#4B4A48] flex flex-col bg-[#131313]/50 backdrop-blur-md">
            <div className="p-6 border-b border-[#4B4A48]/30">
               <div className="relative group">
                  <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-[#4B4A48] group-focus-within:text-[#EFD395] transition-colors" size={16} />
                  <input 
                    type="text" 
                    placeholder="Search Channels..." 
                    className="w-full bg-[#262625] border border-[#4B4A48] rounded px-11 py-3 text-[10px] font-black uppercase italic tracking-widest text-white focus:outline-none focus:border-[#EFD395] transition-all shadow-inner"
                  />
               </div>
            </div>
            
            <div className="flex-1 overflow-y-auto custom-scrollbar no-scrollbar">
               {conversations.map(conv => (
                 <button 
                  key={conv.otherUserId}
                  onClick={() => loadMessages(conv)}
                  className={cn(
                    "w-full p-6 flex gap-5 hover:bg-[#262625] transition-all text-left border-l-4 group relative",
                    activeConv?.otherUserId === conv.otherUserId ? "bg-[#262625] border-[#EFD395]" : "border-transparent"
                  )}
                 >
                   <div className="h-14 w-14 rounded bg-[#131313] border border-[#4B4A48] flex items-center justify-center text-[#EFD395] shrink-0 shadow-inner italic font-black text-lg group-hover:border-[#EFD395] transition-colors relative overflow-hidden">
                      {conv.otherUserName?.[0].toUpperCase() || <User size={24} />}
                   </div>
                   <div className="flex-1 min-w-0">
                      <div className="flex justify-between items-start mb-2">
                         <span className="font-black text-[13px] text-white uppercase italic tracking-tight">{conv.otherUserName}</span>
                         <span className="text-[8px] text-[#777674] uppercase font-black tracking-widest italic">{conv.lastMessageTime?.split('T')[0] || ''}</span>
                      </div>
                      <p className="text-[11px] text-[#A4A4A4] truncate font-black uppercase italic tracking-tighter opacity-60 group-hover:opacity-100 transition-opacity">{conv.lastMessage || 'No transmissions.'}</p>
                   </div>
                   {activeConv?.otherUserId !== conv.otherUserId && (
                     <div className="absolute top-1/2 -translate-y-1/2 right-4 opacity-0 group-hover:opacity-30 transition-opacity">
                        <ChevronRight size={16} className="text-[#EFD395]" />
                     </div>
                   )}
                 </button>
               ))}
               
               {conversations.length === 0 && !loading && (
                 <div className="p-20 text-center border border-dashed border-[#4B4A48] m-6 rounded group">
                    <MessageCircle size={48} className="mx-auto mb-6 text-[#4B4A48] group-hover:text-[#EFD395] transition-colors" />
                    <p className="text-[10px] font-black uppercase tracking-[0.5em] text-[#777674] italic">No Transactions</p>
                 </div>
               )}
            </div>
          </div>

          {/* Chat Window */}
          <div className="flex-1 flex flex-col relative bg-[#131313]">
             <div className="absolute inset-0 bg-gradient-to-b from-[#EFD395]/0 via-transparent to-[#EFD395]/[0.01] pointer-events-none" />
             {activeConv ? (
               <>
                 <div className="flex-1 overflow-y-auto p-10 space-y-8 custom-scrollbar no-scrollbar scroll-smooth" ref={scrollRef}>
                    <div className="text-center mb-10">
                       <span className="px-4 py-1 bg-[#262625] border border-[#4B4A48] rounded text-[8px] font-black text-[#777674] uppercase tracking-[0.4em] italic shadow-inner">Encrypted Channel Established</span>
                    </div>
                    {messages.map((m, idx) => {
                      const isMe = m.senderId !== activeConv.otherUserId;
                      return (
                        <div key={m.id || idx} className={cn("flex flex-col animate-in fade-in slide-in-from-bottom-4 duration-500", isMe ? "items-end" : "items-start")}>
                           <div className={cn(
                             "max-w-[75%] p-6 rounded text-sm font-black uppercase italic tracking-tight shadow-2xl relative group border transition-all",
                             isMe 
                               ? "bg-[#EFD395] text-[#131313] border-[#EFD395] rounded-tr-none hover:shadow-[#EFD395]/10" 
                               : "bg-[#262625] border-[#4B4A48]/50 text-[#FFFFFF] rounded-tl-none hover:border-[#EFD395]/30 shadow-black/50"
                           )}>
                              {m.message}
                              <div className={cn(
                                "absolute bottom-1 right-3 text-[7px] opacity-0 group-hover:opacity-100 transition-opacity flex items-center gap-1 font-black uppercase italic tracking-widest",
                                isMe ? "text-[#131313]/60" : "text-[#777674]"
                              )}>
                                 <Clock size={8} />
                                 {m.timestamp?.split('T')[1].substring(0, 5)}
                              </div>
                           </div>
                        </div>
                      )
                    })}
                 </div>

                 <div className="p-10 bg-[#131313] border-t border-[#4B4A48]">
                    <div className="flex items-center gap-6 bg-[#262625] border border-[#4B4A48] rounded p-2 pl-8 focus-within:border-[#EFD395] transition-all shadow-2xl relative overflow-hidden group/input">
                       <input 
                         type="text" 
                         value={inputText}
                         onChange={e => setInputText(e.target.value)}
                         onKeyPress={e => e.key === 'Enter' && handleSend()}
                         placeholder="Synthesize tactical response..."
                         className="flex-1 bg-transparent py-5 text-sm focus:outline-none placeholder:text-[#4B4A48] font-black uppercase italic text-white"
                       />
                       <div className="flex items-center gap-1 pr-2 relative z-10">
                          <button className="p-4 text-[#4B4A48] hover:text-[#EFD395] transition-colors group/emoji">
                             <Smile size={24} className="group-hover/emoji:scale-110 transition-transform" />
                          </button>
                          <button className="p-4 text-[#4B4A48] hover:text-[#EFD395] transition-colors group/clip">
                             <Paperclip size={24} className="group-hover/clip:scale-110 transition-transform rotate-45" />
                          </button>
                          <button 
                            onClick={handleSend}
                            className="bg-[#EFD395] hover:bg-white text-[#131313] p-5 rounded transition-all shadow-xl active:scale-95 group/send"
                          >
                             <Send size={20} className="group-hover/send:translate-x-1 group-hover/send:-translate-y-1 transition-transform" />
                          </button>
                       </div>
                       <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-[#EFD395]/20 to-transparent opacity-0 group-focus-within/input:opacity-100 transition-opacity" />
                    </div>
                 </div>
               </>
             ) : (
               <div className="flex-1 flex flex-col items-center justify-center p-20 text-center relative overflow-hidden">
                  <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(239,211,149,0.02),transparent_70%)] pointer-events-none" />
                  <div className="h-40 w-40 rounded bg-[#131313] border border-[#4B4A48] flex items-center justify-center mb-12 relative group shadow-2xl shadow-black/80">
                     <div className="absolute inset-0 bg-[#EFD395]/5 rounded-full blur-3xl animate-pulse group-hover:bg-[#EFD395]/10 transition-colors" />
                     <MessageCircle size={80} className="text-[#4B4A48] group-hover:text-[#EFD395]/40 transition-all group-hover:scale-110 duration-700" />
                  </div>
                  <h3 className="text-5xl font-black text-white uppercase italic tracking-tighter mb-6">Command Center</h3>
                  <p className="text-[#A4A4A4] max-w-sm font-black uppercase italic tracking-widest leading-relaxed text-[10px] opacity-40">
                    Select a student transmission channel from the left to initiate tactical real-time guidance.
                  </p>
                  <div className="mt-16 flex items-center gap-8">
                     <div className="h-[1px] w-12 bg-gradient-to-r from-transparent to-[#4B4A48]" />
                     <ShieldCheck className="text-[#4B4A48]/30" size={24} />
                     <div className="h-[1px] w-12 bg-gradient-to-l from-transparent to-[#4B4A48]" />
                  </div>
               </div>
             )}
          </div>
        </div>
      </main>
    </div>
  );
}
