// Portfolio 5: availability vs consistency in practice (needs a replica set: Atlas or docker-compose)
//   mongosh "<connection string>" --file 02_write_concern_and_read_preference.js
const col = db.getSiblingDB("ndfs_nosql").getCollection("dr_demo");
col.drop();

print("--- CP style: critical record, acknowledged by a MAJORITY of nodes before success is reported");
printjson(col.insertOne({ kind: "work_order_closed", wo: "WO-900001", at: new Date() },
                        { writeConcern: { w: "majority", wtimeout: 5000 } }));
print("Read back from the primary with majority read concern (never returns data that could be rolled back):");
printjson(db.getSiblingDB("ndfs_nosql").runCommand({ find: "dr_demo", readConcern: { level: "majority" } }).cursor.firstBatch.length);

print("--- AP style: telemetry, acknowledged by the primary only (fast, tiny risk of loss on failover)");
printjson(col.insertOne({ kind: "telemetry", tag: "EKT-C-201", vibration_mm_s: 3.1, at: new Date() },
                        { writeConcern: { w: 1 } }));

print("--- Read from a secondary (lower latency for a regional dashboard, may lag the primary slightly)");
const secondaryRead = db.getMongo().getDB("ndfs_nosql").getCollection("dr_demo")
                        .find().readPref("secondaryPreferred").toArray();
print("documents seen via secondaryPreferred: " + secondaryRead.length);
