// =====================================================================
// Portfolio 4: CRUD and aggregation queries. Run after 02_insert_data.js
//   mongosh "<connection string>" --file 03_queries.js
// =====================================================================
const ndfs = db.getSiblingDB("ndfs_nosql");

print("\n=== Q1: pumps with flow rate above 300 m3/h (attribute exists only on pumps)");
printjson(ndfs.equipment_specs.find(
  { equipment_type: "PUMP", "specs.flow_rate_m3h": { $gt: 300 } },
  { _id: 0, tag_number: 1, "station.code": 1, "specs.flow_rate_m3h": 1 }).toArray());

print("\n=== Q2: high-pressure compressors (stages >= 2 and discharge above 100 bar)");
printjson(ndfs.equipment_specs.find(
  { equipment_type: "COMPRESSOR", "specs.stages": { $gte: 2 }, "specs.discharge_pressure_bar": { $gt: 100 } },
  { _id: 0, tag_number: 1, "specs.stages": 1, "specs.discharge_pressure_bar": 1 }).toArray());

print("\n=== Q3: parts cost and downtime per equipment tag, 2025 (aggregation pipeline; no join needed)");
printjson(ndfs.work_orders.aggregate([
  { $match: { raised_at: { $gte: new Date("2025-01-01"), $lt: new Date("2026-01-01") } } },
  { $unwind: "$parts" },
  { $group: { _id: "$equipment_tag",
              parts_cost_usd: { $sum: { $multiply: ["$parts.quantity", "$parts.unit_cost_usd"] } },
              orders: { $addToSet: "$wo_number" } } },
  { $project: { parts_cost_usd: 1, work_orders: { $size: "$orders" } } },
  { $sort: { parts_cost_usd: -1 } }
]).toArray());

print("\n=== Q4: hourly average vibration per machine on 5 Nov 2026 (time-series aggregation)");
printjson(ndfs.sensor_telemetry.aggregate([
  { $match: { ts: { $gte: new Date("2026-11-05T00:00:00Z"), $lt: new Date("2026-11-05T06:00:00Z") } } },
  { $group: { _id: { tag: "$meta.tag", hour: { $dateTrunc: { date: "$ts", unit: "hour" } } },
              avg_vibration: { $avg: "$vibration_mm_s" } } },
  { $sort: { "_id.tag": 1, "_id.hour": 1 } },
  { $limit: 12 }
]).toArray());

print("\n=== Q5: ALERT: machines whose peak vibration exceeded 7.1 mm/s in the week (illustrative alarm limit)");
printjson(ndfs.sensor_telemetry.aggregate([
  { $group: { _id: "$meta.tag", peak_vibration: { $max: "$vibration_mm_s" }, readings: { $sum: 1 } } },
  { $match: { peak_vibration: { $gt: 7.1 } } }
]).toArray());

print("\n=== Q6: $lookup (a join in MongoDB): attach equipment specs to the latest emergency orders");
printjson(ndfs.work_orders.aggregate([
  { $match: { wo_type: "EMERGENCY" } },
  { $sort: { raised_at: -1 } },
  { $limit: 3 },
  { $lookup: { from: "equipment_specs", localField: "equipment_tag", foreignField: "tag_number", as: "equipment" } },
  { $project: { wo_number: 1, equipment_tag: 1, raised_at: 1, "equipment.equipment_type": 1, "equipment.manufacturer": 1 } }
]).toArray());

print("\n=== U1: UPDATE: add a certification to a pump ($push) and bump criticality ($set)");
printjson(ndfs.equipment_specs.updateOne(
  { tag_number: "IBN-P-101" },
  { $push: { certifications: { name: "API 610", valid_to: new Date("2028-01-31") } }, $set: { criticality: 1 } }));

print("\n=== U2: UPDATE: close the open work orders for one tag ($set + $currentDate)");
printjson(ndfs.work_orders.updateMany(
  { equipment_tag: "OBG-P-101", status: "OPEN" },
  { $set: { status: "COMPLETED" }, $currentDate: { completed_at: true } }));

print("\n=== C1: CREATE: insert a new equipment document with a DIFFERENT shape (no schema change needed)");
printjson(ndfs.equipment_specs.insertOne({
  tag_number: "OSH-S-301", equipment_type: "SEPARATOR", manufacturer: "NATCO",
  station: { code: "OSH-FS5", region: "OFFSHORE" }, criticality: 1,
  specs: { orientation: "vertical", phases: 2, design_pressure_bar: 60, volume_m3: 30, internals: ["cyclone"] }, certifications: [] }));

print("\n=== V1: VALIDATION: the schema validator rejects an equipment document without a station (expect an error)");
try { ndfs.equipment_specs.insertOne({ tag_number: "BAD-1", equipment_type: "PUMP", specs: {} }); }
catch (e) { print("Rejected as expected: " + e.message); }

print("\n=== D1: DELETE: remove the test document");
printjson(ndfs.equipment_specs.deleteOne({ tag_number: "OSH-S-301" }));
