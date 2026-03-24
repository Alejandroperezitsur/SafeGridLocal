const crypto = require('crypto');

function getTimestamp() {
  return new Date().toISOString();
}

function generateId() {
  return crypto.randomUUID();
}

function addEvent(db, type, severity, description) {
  const id = generateId();
  db.run(`INSERT INTO security_events (id, type, severity, timestamp, description) VALUES (?, ?, ?, ?, ?)`,
    [id, type, severity, getTimestamp(), description]
  );
  return { id, type, severity, timestamp: getTimestamp(), description };
}

function checkFailedLogins(db, username) {
  db.get(`SELECT attempts FROM login_attempts WHERE username = ?`, [username], (err, row) => {
    let attempts = err || !row ? 1 : row.attempts + 1;
    if (!row) {
      db.run(`INSERT INTO login_attempts (username, attempts, lastAttempt) VALUES (?, ?, ?)`, [username, 1, getTimestamp()]);
    } else {
      db.run(`UPDATE login_attempts SET attempts = ?, lastAttempt = ? WHERE username = ?`, [attempts, getTimestamp(), username]);
    }
    
    if (attempts === 6) {
      // Requirements: if (failedLogins > 5) => ALERTA "Posible fuerza bruta"
      addEvent(db, 'Brute Force', 'high', `6 failed login attempts for user ${username}`);
    }
  });
}

function resetFailedLogins(db, username) {
  db.run(`DELETE FROM login_attempts WHERE username = ?`, [username]);
}

function verifyAccessSchedule(db, username) {
  const currentHour = new Date().getHours();
  // Simulate out of hours schedule: e.g. 23:00 to 05:00
  if (currentHour >= 23 || currentHour < 5) {
    addEvent(db, 'Off-Hours Access', 'medium', `Access by ${username} out of schedule (${currentHour}:00)`);
    return false;
  }
  return true;
}

function processUnknownDevice(db, device) {
  if (!device.isTrusted) {
    addEvent(db, 'Unknown Device', 'medium', `Unknown device ${device.name} connected to ${device.zone}`);
  }
}

function simulateAttack(db) {
  const event = addEvent(db, 'Ransomware', 'high', 'Ransomware attack simulated on OT network.');
  
  db.all(`SELECT id FROM devices WHERE zone = 'OT'`, (err, rows) => {
    if(err) return;
    rows.forEach(r => {
      db.run(`UPDATE devices SET status = 'compromised', isTrusted = 0 WHERE id = ?`, [r.id]);
    });
    
    // Risk Propagation to critical systems
    setTimeout(() => {
      db.run(`UPDATE critical_systems SET status = 'down' WHERE name = 'Water Plant'`);
      db.run(`UPDATE critical_systems SET status = 'degraded' WHERE name = 'Energy Grid'`);
      db.run(`UPDATE critical_systems SET status = 'down' WHERE name = 'Textile Production'`);
      addEvent(db, 'System Failure', 'high', 'Critical systems degraded due to OT compromise.');
    }, 1000); // 1 second delay for simulation effect
  });
  
  return event;
}

module.exports = {
  addEvent,
  checkFailedLogins,
  resetFailedLogins,
  verifyAccessSchedule,
  processUnknownDevice,
  simulateAttack
};
