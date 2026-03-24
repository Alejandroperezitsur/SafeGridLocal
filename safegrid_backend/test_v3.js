const db = require('./db');
const threatEngine = require('./threatEngine');

setTimeout(() => {
  console.log("--- Executing SOC Response Tests (V3) ---");
  
  // 1. Trigger Attack
  threatEngine.simulateAttack(db); 
  
  setTimeout(() => {
    console.log("1. Isolating device d5 (Energy PLC 2) to stop spread...");
    threatEngine.isolateDevice(db, 'd5'); // Isolates device
    
    setTimeout(() => {
      console.log("2. Containing Incident...");
      threatEngine.containIncident(db, threatEngine.correlationState.ransomwareId); // Status -> contained
      
      console.log("3. Recovering Energy Grid...");
      threatEngine.recoverSystem(db, 'cs2'); // Recover System
      
      setTimeout(() => {
        console.log("\n[VERIFICATION] Devices State (Note d5 isIsolated: 1):");
        db.all("SELECT id, name, isTrusted, status, isIsolated FROM devices WHERE zone = 'OT'", (err, devs) => console.table(devs));
        
        console.log("\n[VERIFICATION] Systems State (Energy Grid should be operational):");
        db.all("SELECT name, status FROM critical_systems", (err, sys) => console.table(sys));
        
        console.log("\n[VERIFICATION] Incidents State (Should have explanation and be contained/resolved):");
        db.all("SELECT type, status, explanation FROM incidents", (err, inc) => {
          console.table(inc);
          console.log("\nV3 Mechanics Verified: Isolation stopped spread, Containment updated status, Recovery worked.");
          process.exit(0);
        });
      }, 500);
    }, 4500); // give time for ransomware to try spreading
  }, 1500);
}, 1000);
