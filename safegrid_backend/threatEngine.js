const crypto = require('crypto');

function getTimestamp() { return new Date().toISOString(); }
function generateId() { return crypto.randomUUID(); }

function addEvent(db, type, severity, description) {
  const id = generateId();
  db.run(`INSERT INTO security_events (id, type, severity, timestamp, description) VALUES (?, ?, ?, ?, ?)`,
    [id, type, severity, getTimestamp(), description]);
  return { id, type, severity, timestamp: getTimestamp(), description };
}

// ---------------- Phase 2: INCIDENT ENGINE ----------------
function createIncident(db, type, severity, description) {
  const id = generateId();
  db.run(`INSERT INTO incidents (id, type, severity, status, startedAt, affectedDevices, affectedSystems) VALUES (?,?,?,?,?,?,?)`,
    [id, type, severity, 'active', getTimestamp(), '[]', '[]']);
  addTimelineEvent(db, id, 'Incident created: ' + description);
  return id;
}

function addTimelineEvent(db, incidentId, description, deviceId = null) {
  const id = generateId();
  db.run(`INSERT INTO incident_events (id, incidentId, timestamp, description, deviceId) VALUES (?,?,?,?,?)`,
    [id, incidentId, getTimestamp(), description, deviceId]);
}

// Memory-based state for correlation simulation
const correlationState = {
  recentFailedLogins: false,
  recentUnknownDevice: false,
  intrusionIncidentId: null
};

function checkCorrelations(db) {
  if (correlationState.recentFailedLogins && correlationState.recentUnknownDevice && !correlationState.intrusionIncidentId) {
    const incId = createIncident(db, 'intrusion_attempt', 'high', 'Correlated intrusion attempt detected');
    correlationState.intrusionIncidentId = incId;
    addTimelineEvent(db, incId, 'Correlated: Multiple failed logins + Unknown Device');
    addTimelineEvent(db, incId, 'Possible successful access & lateral movement');
  }
}

function checkFailedLogins(db, username) {
  db.get(`SELECT attempts FROM login_attempts WHERE username = ?`, [username], (err, row) => {
    let attempts = err || !row ? 1 : row.attempts + 1;
    if (!row) db.run(`INSERT INTO login_attempts (username, attempts, lastAttempt) VALUES (?, ?, ?)`, [username, 1, getTimestamp()]);
    else db.run(`UPDATE login_attempts SET attempts = ?, lastAttempt = ? WHERE username = ?`, [attempts, getTimestamp(), username]);
    
    if (attempts >= 5) {
      addEvent(db, 'Brute Force', 'high', `Failed login attempts for user ${username}`);
      correlationState.recentFailedLogins = true;
      if (correlationState.intrusionIncidentId) {
        addTimelineEvent(db, correlationState.intrusionIncidentId, 'Continued brute force login detected');
      } else {
        checkCorrelations(db);
      }
    }
  });
}

function processUnknownDevice(db, device) {
  if (!device.isTrusted) {
    addEvent(db, 'Unknown Device', 'medium', `Unknown device ${device.name} connected to ${device.zone}`);
    correlationState.recentUnknownDevice = true;
    if (correlationState.intrusionIncidentId) {
      addTimelineEvent(db, correlationState.intrusionIncidentId, `Unknown device ${device.name} activity`, device.id);
    } else {
      checkCorrelations(db);
    }
  }
}

// ---------------- CASCADING DEGRADATION ----------------
function evaluateSystemDependencies(db) {
  db.all(`SELECT * FROM critical_systems`, (err, systems) => {
    if (err) return;
    const statusMap = {};
    systems.forEach(s => statusMap[s.name] = s.status);

    const checkAndCascade = (sysName, dependencies) => {
      let isDown = false;
      dependencies.forEach(dep => {
        if (statusMap[dep] === 'down' || statusMap[dep] === 'degraded') {
          isDown = true;
        }
      });
      if (isDown && statusMap[sysName] === 'operational') {
        db.run(`UPDATE critical_systems SET status = 'down' WHERE name = ?`, [sysName]);
        statusMap[sysName] = 'down';
        
        // Log to ransomware incident if running
        if (correlationState.ransomwareId) {
           addTimelineEvent(db, correlationState.ransomwareId, `Cascading Failure: ${sysName} went down due to dependencies`);
        }
        return true; 
      }
      return false;
    };

    // If Energy Grid falls, Water Plant falls. If Water Plant or Energy Grid falls, Textile Production falls.
    checkAndCascade('Water Plant', ['Energy Grid']);
    checkAndCascade('Textile Production', ['Water Plant', 'Energy Grid']);
  });
}

function updateSystemStatusFromDevices(db) {
  // OT compromise -> degrade energy grid (triggering cascade)
  db.all(`SELECT count(*) as compCount FROM devices WHERE zone = 'OT' AND status = 'compromised'`, (err, row) => {
    if (row && row.compCount > 0) {
      db.run(`UPDATE critical_systems SET status = 'down' WHERE name = 'Energy Grid'`, () => {
         evaluateSystemDependencies(db);
      });
    }
  });
}

// ---------------- RANSOMWARE PROPAGATION ----------------
function propagateRansomware(db) {
  const incId = createIncident(db, 'ransomware', 'critical', 'Ransomware propagation detected on OT');
  correlationState.ransomwareId = incId;
  addTimelineEvent(db, incId, 'Initial ransomware payload execution detected');

  db.all(`SELECT id, name, zone FROM devices WHERE zone = 'OT'`, (err, rows) => {
    if(err || !rows) return;
    
    let delay = 1000;
    rows.forEach(r => {
        setTimeout(() => {
          db.run(`UPDATE devices SET status = 'compromised', isTrusted = 0 WHERE id = ?`, [r.id], () => {
             addTimelineEvent(db, incId, `Device ${r.name} infected and encrypted by ransomware`, r.id);
             addEvent(db, 'Ransomware spread', 'high', `${r.name} compromised`);
             updateSystemStatusFromDevices(db);
          });
        }, delay);
        delay += 2500; // Realism: Time delay in spreading
    });
  });
}

function verifyAccessSchedule(db, username) { return true; }

module.exports = {
  addEvent,
  checkFailedLogins,
  resetFailedLogins: (db, user) => db.run(`DELETE FROM login_attempts WHERE username = ?`, [user]),
  verifyAccessSchedule,
  processUnknownDevice,
  simulateAttack: propagateRansomware,
  correlationState
};
