const express = require('express');
const cors = require('cors');
const db = require('./db');
const threatEngine = require('./threatEngine');

const app = express();
app.use(cors());
app.use(express.json());

// --- Authentication ---
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  if(!username || !password) return res.status(400).json({error: 'Missing credentials'});

  db.get(`SELECT * FROM users WHERE username = ?`, [username], (err, user) => {
    if (err) return res.status(500).json({error: 'Database error'});
    if (!user || user.password !== password) {
      threatEngine.checkFailedLogins(db, username);
      return res.status(401).json({error: 'Invalid credentials'});
    }
    threatEngine.resetFailedLogins(db, username);
    res.json({ id: user.id, name: user.name, role: user.role, username: user.username });
  });
});

// --- Devices ---
app.get('/api/devices', (req, res) => {
  db.all(`SELECT * FROM devices`, (err, rows) => {
    if(err) return res.status(500).json({error: err.message});
    const devices = rows.map(r => ({...r, isTrusted: r.isTrusted === 1, isIsolated: r.isIsolated === 1}));
    res.json(devices);
  });
});

app.post('/api/devices', (req, res) => {
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

// --- Incidents & Events ---
app.get('/api/events', (req, res) => {
  db.all(`SELECT * FROM security_events ORDER BY timestamp DESC`, (err, rows) => res.json(rows));
});

app.get('/api/incidents', (req, res) => {
  db.all(`SELECT * FROM incidents ORDER BY startedAt DESC`, (err, incidents) => {
    if(err) return res.status(500).json({error: err.message});
    db.all(`SELECT * FROM incident_events ORDER BY timestamp ASC`, (err, events) => {
      const result = incidents.map(inc => ({
        ...inc,
        timeline: events.filter(e => e.incidentId === inc.id)
      }));
      res.json(result);
    });
  });
});

// --- Systems ---
app.get('/api/systems', (req, res) => {
  db.all(`SELECT * FROM critical_systems`, (err, rows) => {
    if(err) return res.status(500).json({error: err.message});
    const systems = rows.map(r => ({...r, dependencies: JSON.parse(r.dependencies || '[]')}));
    res.json(systems);
  });
});

// --- Actions (Simulation Engine) ---
app.post('/api/simulate', (req, res) => {
  const { role } = req.body;
  if(role !== 'admin') return res.status(403).json({error: 'Unauthorized'});
  threatEngine.simulateAttack(db);
  res.json({ message: 'Ransomware sequence initiated' });
});

app.post('/api/reset', (req, res) => {
  const { role } = req.body;
  if(role !== 'admin') return res.status(403).json({error: 'Unauthorized'});

  db.run(`UPDATE devices SET status = 'online', isTrusted = 1, isIsolated = 0`);
  db.run(`UPDATE critical_systems SET status = 'operational'`);
  db.run(`DELETE FROM security_events`);
  db.run(`DELETE FROM login_attempts`);
  db.run(`DELETE FROM incidents`);
  db.run(`DELETE FROM incident_events`);
  
  threatEngine.correlationState.recentFailedLogins = false;
  threatEngine.correlationState.recentUnknownDevice = false;
  threatEngine.correlationState.intrusionIncidentId = null;
  threatEngine.correlationState.ransomwareId = null;
  
  res.json({ message: 'Engine reset completed' });
});

// ---------------- RESPONSE ACTIONS API (V3) ----------------
app.post('/api/respond/isolate', (req, res) => {
  const { deviceId, role } = req.body;
  if(role !== 'admin' && role !== 'operator') return res.status(403).json({error: 'Unauthorized'});
  threatEngine.isolateDevice(db, deviceId);
  res.json({ message: `Device ${deviceId} isolated` });
});

app.post('/api/respond/shutdown_zone', (req, res) => {
  const { zone, role } = req.body;
  if(role !== 'admin') return res.status(403).json({error: 'Admin only'});
  threatEngine.shutdownZone(db, zone);
  res.json({ message: `Zone ${zone} emergency shutdown` });
});

app.post('/api/respond/contain', (req, res) => {
  const { incidentId, role } = req.body;
  if(role !== 'admin' && role !== 'operator') return res.status(403).json({error: 'Unauthorized'});
  threatEngine.containIncident(db, incidentId);
  res.json({ message: `Incident ${incidentId} contained` });
});

app.post('/api/respond/recover', (req, res) => {
  const { systemId, role } = req.body;
  if(role !== 'admin' && role !== 'operator') return res.status(403).json({error: 'Unauthorized'});
  threatEngine.recoverSystem(db, systemId);
  res.json({ message: `System ${systemId} recovered` });
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`SafeGrid Engine V3 running on port ${PORT} across all interfaces`));
