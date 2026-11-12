// =====================================================================
// Portfolio 4: MongoDB collections for the NDFS case study
// Run (local):  mongosh "mongodb://localhost:27017" --file 01_setup_collections.js
// Run (Atlas):  mongosh "<your Atlas connection string>" --file 01_setup_collections.js
// =====================================================================
const ndfs = db.getSiblingDB("ndfs_nosql");
ndfs.dropDatabase();

// 1) equipment_specs : DOCUMENT model. Each equipment type has different technical attributes,
//    which is awkward in a fixed relational table (many NULL columns) but natural in a document.
ndfs.createCollection("equipment_specs", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["tag_number", "equipment_type", "station", "specs"],
    properties: {
      tag_number:     { bsonType: "string" },
      equipment_type: { enum: ["PUMP","COMPRESSOR","SEPARATOR","HEATER_TREATER","GENERATOR","VALVE","TANK"] },
      station:        { bsonType: "object", required: ["code","region"] },
      specs:          { bsonType: "object" }
    }}},
  validationAction: "error"
});

// 2) work_orders : DOCUMENT model with EMBEDDED assignments and parts
//    (they are always read together with the order; this replaces two junction tables and joins).
ndfs.createCollection("work_orders");

// 3) sensor_telemetry : TIME-SERIES collection for high-velocity IoT readings
try {
  ndfs.createCollection("sensor_telemetry", {
    timeseries: { timeField: "ts", metaField: "meta", granularity: "minutes" }
  });
  print("sensor_telemetry created as a TIME-SERIES collection");
} catch (e) {
  print("Time-series not available on this server (" + e.message + "); using a regular collection instead");
  ndfs.createCollection("sensor_telemetry");
}

printjson(ndfs.getCollectionNames());
