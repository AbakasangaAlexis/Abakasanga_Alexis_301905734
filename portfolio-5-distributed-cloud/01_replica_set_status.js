// Portfolio 5: show the replica set topology (works on Atlas M0 and on the local docker-compose set)
//   mongosh "<connection string>" --file 01_replica_set_status.js
const hello = db.hello();
print("Replica set name : " + hello.setName);
print("This node is     : " + (hello.isWritablePrimary ? "PRIMARY" : "SECONDARY"));
print("Members          : " + JSON.stringify(hello.hosts));
try {                                   // rs.status() is not allowed on some Atlas tiers; hello() above always works
  rs.status().members.forEach(m => print(m.name + "  " + m.stateStr + "  health=" + m.health));
} catch (e) { print("rs.status() not permitted here: " + e.codeName); }
