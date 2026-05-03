const crypto = require('crypto');

function getTimestamp() { return new Date().toISOString(); }
function generateId() { return crypto.randomUUID(); }

function addEvent(db, type, severity, description) {
  const id = generateId();
  db.run(`INSERT INTO security_events (id, type, severity, timestamp, description) VALUES (?, ?, ?, ?, ?)`,
    [id, type, severity, getTimestamp(), description]);
  return { id, type, severity, timestamp: getTimestamp(), description };
}

// ---------------- Phase 2+3: INCIDENT ENGINE ----------------
function createIncident(db, type, severity, description) {
  const id = generateId();
  db.run(`INSERT INTO incidents (id, type, severity, status, startedAt, affectedDevices, affectedSystems, explanation) VALUES (?,?,?,?,?,?,?,?)`,
    [id, type, severity, 'active', getTimestamp(), '[]', '[]', '']);
  addTimelineEvent(db, id, 'Incidente creado: ' + description);
  return id;
}

function addTimelineEvent(db, incidentId, description, deviceId = null) {
  const id = generateId();
  db.run(`INSERT INTO incident_events (id, incidentId, timestamp, description, deviceId) VALUES (?,?,?,?,?)`,
    [id, incidentId, getTimestamp(), description, deviceId]);
}

const correlationState = {
  recentFailedLogins: false,
  recentUnknownDevice: false,
  intrusionIncidentId: null,
  ransomwareId: null
};

function checkCorrelations(db) {
  if (correlationState.recentFailedLogins && correlationState.recentUnknownDevice && !correlationState.intrusionIncidentId) {
    const incId = createIncident(db, 'intrusion_attempt', 'high', 'Intento de intrusión correlacionado detectado');
    correlationState.intrusionIncidentId = incId;
    addTimelineEvent(db, incId, 'Correlación: Múltiples inicios de sesión fallidos + Dispositivo desconocido');
  }
}

function checkFailedLogins(db, username) {
  db.get(`SELECT attempts FROM login_attempts WHERE username = ?`, [username], (err, row) => {
    let attempts = err || !row ? 1 : row.attempts + 1;
    if (!row) db.run(`INSERT INTO login_attempts (username, attempts, lastAttempt) VALUES (?, ?, ?)`, [username, 1, getTimestamp()]);
    else db.run(`UPDATE login_attempts SET attempts = ?, lastAttempt = ? WHERE username = ?`, [attempts, getTimestamp(), username]);
    
    if (attempts >= 5) {
      addEvent(db, 'Brute Force', 'high', `Intentos de inicio de sesión fallidos para el usuario ${username}`);
      correlationState.recentFailedLogins = true;
      if (correlationState.intrusionIncidentId) addTimelineEvent(db, correlationState.intrusionIncidentId, 'Intento de fuerza bruta continuo detectado');
      else checkCorrelations(db);
    }
  });
}

function processUnknownDevice(db, device) {
  if (!device.isTrusted) {
    addEvent(db, 'Unknown Device', 'medium', `Dispositivo desconocido ${device.name} conectado a la zona ${device.zone}`);
    correlationState.recentUnknownDevice = true;
    if (correlationState.intrusionIncidentId) addTimelineEvent(db, correlationState.intrusionIncidentId, `Actividad del dispositivo desconocido ${device.name}`, device.id);
    else checkCorrelations(db);
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
        if (statusMap[dep] === 'down' || statusMap[dep] === 'degraded') isDown = true;
      });
      if (isDown && statusMap[sysName] === 'operational') {
        db.run(`UPDATE critical_systems SET status = 'down' WHERE name = ?`, [sysName]);
        statusMap[sysName] = 'down';
        
        if (correlationState.ransomwareId) {
           addTimelineEvent(db, correlationState.ransomwareId, `Falla en Cascada: ${sysName} colapsó debido a dependencias afectadas`);
           const explanation = `El sistema ${sysName} colapsó porque depende de: [${dependencies.join(', ')}], el cual fue comprometido por la propagación de Ransomware desde la red OT.`;
           db.run(`UPDATE incidents SET explanation = ? WHERE id = ?`, [explanation, correlationState.ransomwareId]);
        }
        return true; 
      }
      return false;
    };

    checkAndCascade('Water Plant', ['Energy Grid']);
    checkAndCascade('Textile Production', ['Water Plant', 'Energy Grid']);
  });
}

function updateSystemStatusFromDevices(db) {
  db.get(`SELECT count(*) as compCount FROM devices WHERE zone = 'OT' AND status = 'compromised'`, (err, row) => {
    if (row && row.compCount > 0) {
      db.run(`UPDATE critical_systems SET status = 'down' WHERE name = 'Energy Grid'`, () => {
         evaluateSystemDependencies(db);
      });
    }
  });
}

// ---------------- RANSOMWARE PROPAGATION V3 ----------------
function propagateRansomware(db) {
  const incId = createIncident(db, 'ransomware', 'critical', 'Propagación de Ransomware detectada en la red OT');
  correlationState.ransomwareId = incId;
  addTimelineEvent(db, incId, 'Ejecución inicial del payload de ransomware detectada');

  db.all(`SELECT id, name, zone FROM devices WHERE zone = 'OT'`, (err, rows) => {
    if(err || !rows) return;
    
    let delay = 1000;
    rows.forEach(r => {
        setTimeout(() => {
          // Verify isolation state before infecting!
          db.get(`SELECT isIsolated FROM devices WHERE id = ?`, [r.id], (err, currentDev) => {
            if (currentDev && currentDev.isIsolated === 1) {
               addTimelineEvent(db, incId, `Infección bloqueada: El dispositivo ${r.name} está aislado de la red`, r.id);
               return; // STOP
            }
            db.run(`UPDATE devices SET status = 'compromised', isTrusted = 0 WHERE id = ?`, [r.id], () => {
               addTimelineEvent(db, incId, `Dispositivo ${r.name} infectado y encriptado por ransomware`, r.id);
               addEvent(db, 'Ransomware spread', 'high', `${r.name} comprometido`);
               updateSystemStatusFromDevices(db);
            });
          });
        }, delay);
        delay += 4000; // 4 seconds delay to give human response time
    });
  });
}

// ---------------- RESPONSE ACTIONS V3 ----------------
function isolateDevice(db, deviceId) {
  db.run(`UPDATE devices SET isIsolated = 1, status = 'offline' WHERE id = ?`, [deviceId]);
  if(correlationState.ransomwareId) addTimelineEvent(db, correlationState.ransomwareId, `ACCIÓN SOC: Dispositivo ${deviceId} aislado de la red`, deviceId);
}

function reconnectDevice(db, deviceId) {
  db.run(`UPDATE devices SET isIsolated = 0, status = 'online' WHERE id = ?`, [deviceId]);
  if(correlationState.ransomwareId) addTimelineEvent(db, correlationState.ransomwareId, `ACCIÓN SOC: Dispositivo ${deviceId} reconectado a la red`, deviceId);
}

function shutdownZone(db, zone) {
  db.run(`UPDATE devices SET status = 'offline', isIsolated = 1 WHERE zone = ?`, [zone]);
  if(correlationState.ransomwareId) addTimelineEvent(db, correlationState.ransomwareId, `ACCIÓN SOC: Apagado de emergencia ejecutado para la zona ${zone}`);
}

function containIncident(db, incidentId) {
  db.run(`UPDATE incidents SET status = 'contained' WHERE id = ?`, [incidentId]);
  addTimelineEvent(db, incidentId, `ACCIÓN SOC: Incidente marcado como CONTENIDO por el operador`);
}

function recoverSystem(db, systemId) {
  db.run(`UPDATE critical_systems SET status = 'operational' WHERE id = ?`, [systemId]);
  if(correlationState.ransomwareId) {
    addTimelineEvent(db, correlationState.ransomwareId, `RECUPERACIÓN: Sistema ${systemId} restaurado a su estado operativo`);
    // Auto-resolve incident upon full recovery check (simplification)
    db.run(`UPDATE incidents SET status = 'resolved' WHERE id = ?`, [correlationState.ransomwareId]);
  }
}

module.exports = {
  addEvent,
  checkFailedLogins,
  resetFailedLogins: (db, user) => db.run(`DELETE FROM login_attempts WHERE username = ?`, [user]),
  verifyAccessSchedule: () => true,
  processUnknownDevice,
  simulateAttack: propagateRansomware,
  correlationState,
  isolateDevice,
  reconnectDevice,
  shutdownZone,
  containIncident,
  recoverSystem
};
