import net from 'net';

const host = 'aws-1-ap-south-1.pooler.supabase.com';
const ports = [5432, 6543];

const checkPort = (port) => {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    const timeout = 5000;
    
    socket.setTimeout(timeout);
    
    console.log(`🔍 Testing ${host}:${port}...`);
    
    socket.on('connect', () => {
      console.log(`✅ SUCCESS: Port ${port} is OPEN and REACHABLE.`);
      socket.destroy();
      resolve(true);
    });
    
    socket.on('timeout', () => {
      console.log(`❌ FAILED: Port ${port} timed out after ${timeout/1000}s.`);
      socket.destroy();
      resolve(false);
    });
    
    socket.on('error', (err) => {
      console.log(`❌ FAILED: Port ${port} error: ${err.message}`);
      socket.destroy();
      resolve(false);
    });
    
    socket.connect(port, host);
  });
};

console.log('--- Database Network Diagnostic ---');
for (const port of ports) {
  await checkPort(port);
}
console.log('-----------------------------------');
console.log('If both fail, you are likely on a restricted network (Wifi/Firewall).');
console.log('If 5432 succeeds but Prisma still fails, please check your .env credentials.');
