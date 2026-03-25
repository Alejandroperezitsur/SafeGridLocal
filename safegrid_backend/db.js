const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'database.sqlite');
const db = new sqlite3.Database(dbPath);

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, name TEXT, role TEXT, username TEXT UNIQUE, password TEXT)`);
  db.run(`CREATE TABLE IF NOT EXISTS devices (id TEXT PRIMARY KEY, name TEXT, ip TEXT, type TEXT, zone TEXT, isTrusted INTEGER, status TEXT, isIsolated INTEGER DEFAULT 0)`);
  db.run(`CREATE TABLE IF NOT EXISTS security_events (id TEXT PRIMARY KEY, type TEXT, severity TEXT, timestamp TEXT, description TEXT)`);
  db.run(`CREATE TABLE IF NOT EXISTS critical_systems (id TEXT PRIMARY KEY, name TEXT, status TEXT, dependencies TEXT)`);
  db.run(`CREATE TABLE IF NOT EXISTS login_attempts (username TEXT PRIMARY KEY, attempts INTEGER, lastAttempt TEXT)`);
  
  // Phase 3: Incident Engine Explanations
  db.run(`CREATE TABLE IF NOT EXISTS incidents (
    id TEXT PRIMARY KEY,
    type TEXT,
    severity TEXT,
    status TEXT,
    startedAt TEXT,
    affectedDevices TEXT,
    affectedSystems TEXT,
    explanation TEXT
  )`);
  
  // If table exists but no explanation column, try to alter (SQLite fallback)
  db.run(`ALTER TABLE incidents ADD COLUMN explanation TEXT`, (err) => { /* ignore if exists */ });
  db.run(`ALTER TABLE devices ADD COLUMN isIsolated INTEGER DEFAULT 0`, (err) => { /* ignore */ });
  
  db.run(`CREATE TABLE IF NOT EXISTS incident_events (
    id TEXT PRIMARY KEY,
    incidentId TEXT,
    timestamp TEXT,
    description TEXT,
    deviceId TEXT
  )`);

  // Seeds
  db.get('SELECT COUNT(*) as count FROM users', (err, row) => {
    if (row && row.count === 0) {
      db.run(`INSERT INTO users (id, name, role, username, password) VALUES ('u1', 'Admin', 'admin', 'admin', 'admin123')`);
      db.run(`INSERT INTO users (id, name, role, username, password) VALUES ('u2', 'Operator', 'operator', 'operator', 'op123')`);
      db.run(`INSERT INTO users (id, name, role, username, password) VALUES ('u3', 'Viewer', 'viewer', 'viewer', 'view123')`);
    }
  });

  db.get('SELECT COUNT(*) as count FROM devices', (err, row) => {
    if (row && row.count === 0) {
      const devices = [
        {id: 'd1', name: 'IT Router', ip: '192.168.1.1', type: 'router', zone: 'IT', isTrusted: 1, status: 'online'},
        {id: 'd2', name: 'Admin PC', ip: '192.168.1.5', type: 'pc', zone: 'IT', isTrusted: 1, status: 'online'},
        {id: 'd3', name: 'Scada Server', ip: '10.0.0.10', type: 'pc', zone: 'DMZ', isTrusted: 1, status: 'online'},
        {id: 'd4', name: 'Water PLC 1', ip: '192.168.10.50', type: 'plc', zone: 'OT', isTrusted: 1, status: 'online'},
        {id: 'd5', name: 'Energy PLC 2', ip: '192.168.10.51', type: 'plc', zone: 'OT', isTrusted: 1, status: 'online'},
        {id: 'd6', name: 'Textile Machine', ip: '192.168.10.52', type: 'plc', zone: 'OT', isTrusted: 1, status: 'online'}
      ];
      devices.forEach(d => {
        db.run(`INSERT INTO devices (id, name, ip, type, zone, isTrusted, status) VALUES (?,?,?,?,?,?,?)`, [d.id, d.name, d.ip, d.type, d.zone, d.isTrusted, d.status]);
      });
    }
  });

  db.get('SELECT COUNT(*) as count FROM critical_systems', (err, row) => {
    if (row && row.count === 0) {
      db.run(`INSERT INTO critical_systems (id, name, status, dependencies) VALUES ('cs1', 'Water Plant', 'operational', '["Energy Grid"]')`);
      db.run(`INSERT INTO critical_systems (id, name, status, dependencies) VALUES ('cs2', 'Energy Grid', 'operational', '[]')`);
      db.run(`INSERT INTO critical_systems (id, name, status, dependencies) VALUES ('cs3', 'Textile Production', 'operational', '["Energy Grid", "Water Plant"]')`);
    }
  });
});

module.exports = db;
