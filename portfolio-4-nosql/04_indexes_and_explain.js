// =====================================================================
// Portfolio 4: Indexing and query plans in MongoDB (compare with the PostgreSQL plans in Portfolio 2)
//   mongosh "<connection string>" --file 04_indexes_and_explain.js
// Look at: winningPlan.stage (COLLSCAN vs IXSCAN), totalDocsExamined, nReturned, executionTimeMillis
// =====================================================================
const ndfs = db.getSiblingDB("ndfs_nosql");
function summary(label, ex) {
  const s = ex.executionStats;
  print(label + ": stage=" + JSON.stringify(ex.queryPlanner.winningPlan.stage || ex.queryPlanner.winningPlan.inputStage?.stage) +
        "  docsExamined=" + s.totalDocsExamined + "  keysExamined=" + s.totalKeysExamined +
        "  returned=" + s.nReturned + "  time=" + s.executionTimeMillis + " ms");
}

ndfs.work_orders.dropIndexes();   // start clean (keeps only _id)
const q = { equipment_tag: "OBG-P-101", wo_type: "EMERGENCY" };

print("--- BEFORE index");
summary("work_orders by tag+type",
  ndfs.work_orders.find(q).sort({ raised_at: -1 }).explain("executionStats"));

ndfs.work_orders.createIndex({ equipment_tag: 1, wo_type: 1, raised_at: -1 }, { name: "idx_tag_type_raised" });
ndfs.equipment_specs.createIndex({ tag_number: 1 }, { unique: true, name: "uq_tag" });
ndfs.equipment_specs.createIndex({ equipment_type: 1, "station.code": 1 }, { name: "idx_type_station" });
// partial index: only open orders (same idea as the PostgreSQL partial index)
ndfs.work_orders.createIndex({ priority: 1, raised_at: 1 }, { name: "idx_open_backlog", partialFilterExpression: { status: "OPEN" } });

print("--- AFTER index");
summary("work_orders by tag+type",
  ndfs.work_orders.find(q).sort({ raised_at: -1 }).explain("executionStats"));
summary("open backlog (partial index)",
  ndfs.work_orders.find({ status: "OPEN" }).sort({ priority: 1, raised_at: 1 }).explain("executionStats"));

print("--- Indexes present");
printjson(ndfs.work_orders.getIndexes().map(i => i.name));
printjson(ndfs.equipment_specs.getIndexes().map(i => i.name));
