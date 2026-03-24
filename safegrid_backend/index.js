const express = require('express');
const cors = require('cors');
const db = require('./db');
const threatEngine = require('./threatEngine');

const app = express();
app.use(cors());
app.use(express.json());

// --- Authentication --- //
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  if(!username || !password) return res.status(400).json({error: 'Missing credentials'});

  db.get(`SELECT * FROM users WHERE username = ?`, [username], (err, user) => {
    if (err) return res.status(500).json({error: 'Database error'});
    if (!user || user.password !== password) {
      threatEngine.checkFailedLogins(db, username); // track failed logins
      return res.status(401).json({error: 'Invalid credentials'});
    }
    
    threatEngine.resetFailedLogins(db, username);
    threatEngine.verifyAccessSchedule(db, username);
    
    res.json({ id: user.id, name: user.name, role: user.role, username: user.username });
  });
});

// --- Devices (Network Map) --- //
app.get('/api/devices', (req, res) => {
  db.all(`SELECT * FROM devices`, (err, rows) => {
    if(err) return res.status(500).json({error: err.message});
    const devices = rows.map(r => ({...r, isTrusted: r.isTrusted === 1}));
    res.json(devices);
  });
});

app.post('/api/devices', (req, res) => {
  // To test unknown device insertion
  const { id = Date.now().toString(), name, ip, type, zone, isTrusted=0, status='online' } = req.body;
  const isTrustedInt = isTrusted ? 1 : 0;
  
  db.run(`INSERT INTO devices (id, name, ip, type, zone, isTrusted, status) VALUES (?,?,?,?,?,?,?)`,
    [id, name, ip, type, zone, isTrustedInt, status], function(err) {
      if(err) return res.status(500).json({error: err.message});
      const newD = { id, name, ip, type, zone, isTrusted: !!isTrusted, status };
      threatEngine.processUnknownDevice(db, newD);
      res.json(newD);
  });
});

// --- Security Events (Alerts) --- //
app.get('/api/events', (req, res) => {
  db.all(`SELECT * FROM security_events ORDER BY timestamp DESC`, (err, rows) => {
    if(err) return res.status(500).json({error: err.message});
    res.json(rows);
  });
});

// --- Critical Systems --- //
app.get('/api/systems', (req, res) => {
  db.all(`SELECT * FROM critical_systems`, (err, rows) => {
    if(err) return res.status(500).json({error: err.message});
    const systems = rows.map(r => ({...r, dependencies: JSON.parse(r.dependencies || '[]')}));
    res.json(systems);
  });
});

// --- Actions (Simulation Engine) --- //
app.post('/api/simulate', (req, res) => {
  const { role } = req.body;
  // Admin simulation restriction
  if(role !== 'admin') return res.status(403).json({error: 'Unauthorized: Admins only can simulate attacks.'});
  
  const event = threatEngine.simulateAttack(db);
  res.json({ message: 'Attack sequence initiated', event });
});

app.post('/api/reset', (req, res) => {
  const { role } = req.body;
  if(role !== 'admin') return res.status(403).json({error: 'Unauthorized'});

  db.run(`UPDATE devices SET status = 'online', isTrusted = 1`);
  db.run(`UPDATE critical_systems SET status = 'operational'`);
  db.run(`DELETE FROM security_events`);
  db.run(`DELETE FROM login_attempts`);
  res.json({ message: 'Simulation reset completed' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`SafeGrid Engine running on http://localhost:${PORT}`));
