// =====================================================================
// Portfolio 4: Load data. Run after 01_setup_collections.js
//   mongosh "<connection string>" --file 02_insert_data.js
// Data is fictional and generated with a seeded generator so results are repeatable.
// =====================================================================
const ndfs = db.getSiblingDB("ndfs_nosql");

// ---- tiny seeded random generator (so every run produces the same data) ----
let seed = 42;
function rnd() { seed = (seed * 1664525 + 1013904223) % 4294967296; return seed / 4294967296; }
function pick(a) { return a[Math.floor(rnd() * a.length)]; }

// ---------------- equipment_specs (hand-written: note the different "specs" per type) ----------------
ndfs.equipment_specs.insertMany([
  { tag_number: "EKT-P-101", equipment_type: "PUMP", manufacturer: "Flowserve",
    station: { code: "EKT-FS1", region: "ONSHORE_EAST" }, criticality: 1,
    specs: { flow_rate_m3h: 420, head_m: 95, motor_kw: 160, seal_type: "double mechanical", rpm: 2980 },
    certifications: [ { name: "API 610", valid_to: new Date("2027-03-01") } ] },
  { tag_number: "OBG-P-101", equipment_type: "PUMP", manufacturer: "Flowserve",
    station: { code: "OBG-FS3", region: "ONSHORE_WEST" }, criticality: 1,
    specs: { flow_rate_m3h: 510, head_m: 110, motor_kw: 200, seal_type: "single mechanical", rpm: 2980 },
    certifications: [ { name: "API 610", valid_to: new Date("2026-12-15") } ] },
  { tag_number: "IBN-P-101", equipment_type: "PUMP", manufacturer: "Sulzer",
    station: { code: "IBN-FS2", region: "ONSHORE_EAST" }, criticality: 2,
    specs: { flow_rate_m3h: 260, head_m: 70, motor_kw: 90, seal_type: "single mechanical", rpm: 1480 }, certifications: [] },
  { tag_number: "EKT-C-201", equipment_type: "COMPRESSOR", manufacturer: "Atlas Copco",
    station: { code: "EKT-FS1", region: "ONSHORE_EAST" }, criticality: 1,
    specs: { stages: 2, discharge_pressure_bar: 120, capacity_mmscfd: 18, driver: "gas engine", lube_oil_litres: 800 },
    certifications: [ { name: "API 618", valid_to: new Date("2027-08-30") } ] },
  { tag_number: "OBG-C-201", equipment_type: "COMPRESSOR", manufacturer: "Dresser-Rand",
    station: { code: "OBG-FS3", region: "ONSHORE_WEST" }, criticality: 1,
    specs: { stages: 3, discharge_pressure_bar: 160, capacity_mmscfd: 30, driver: "gas turbine", lube_oil_litres: 1500 }, certifications: [] },
  { tag_number: "OSH-C-201", equipment_type: "COMPRESSOR", manufacturer: "Dresser-Rand",
    station: { code: "OSH-FS5", region: "OFFSHORE" }, criticality: 1,
    specs: { stages: 1, discharge_pressure_bar: 90, capacity_mmscfd: 12, driver: "electric motor", lube_oil_litres: 400 }, certifications: [] },
  { tag_number: "EKT-S-301", equipment_type: "SEPARATOR", manufacturer: "NATCO",
    station: { code: "EKT-FS1", region: "ONSHORE_EAST" }, criticality: 2,
    specs: { orientation: "horizontal", phases: 3, design_pressure_bar: 40, volume_m3: 55, internals: ["weir", "demister"] }, certifications: [] },
  { tag_number: "IBN-G-401", equipment_type: "GENERATOR", manufacturer: "Caterpillar",
    station: { code: "IBN-FS2", region: "ONSHORE_EAST" }, criticality: 1,
    specs: { rating_kva: 1250, fuel: "diesel", voltage_v: 415, service_interval_hours: 1000 }, certifications: [] },
  { tag_number: "BNY-G-401", equipment_type: "GENERATOR", manufacturer: "Caterpillar",
    station: { code: "BNY-FS4", region: "SWAMP" }, criticality: 1,
    specs: { rating_kva: 800, fuel: "gas", voltage_v: 415, service_interval_hours: 1000 }, certifications: [] },
  { tag_number: "IBN-T-501", equipment_type: "TANK", manufacturer: "Local Fabricator",
    station: { code: "IBN-FS2", region: "ONSHORE_EAST" }, criticality: 3,
    specs: { capacity_bbl: 20000, roof: "floating", product: "crude oil", last_gauge_calibration: new Date("2026-02-10") }, certifications: [] }
]);
print("equipment_specs: " + ndfs.equipment_specs.countDocuments());

// ---------------- work_orders (20,000 generated; embedded assignments and parts) ----------------
const tags = ndfs.equipment_specs.distinct("tag_number");
const techs = ["Emem Udoh", "Chidi Okeke", "Ngozi Eze", "Bassey Etim", "Tamuno Briggs", "Ifeanyi Nwosu"];
const partCatalog = [
  { part_number: "MS-5521",  unit_cost_usd: 850 }, { part_number: "BRG-6310", unit_cost_usd: 240 },
  { part_number: "FLT-0098", unit_cost_usd: 95.5 }, { part_number: "GSK-7710", unit_cost_usd: 60 },
  { part_number: "SNS-3301", unit_cost_usd: 780 }
];
const start = new Date("2021-01-01").getTime(), span = new Date("2026-10-25").getTime() - start;
let batch = [];
for (let i = 1; i <= 20000; i++) {
  const raised = new Date(start + rnd() * span);
  const status = rnd() < 0.998 ? "COMPLETED" : "OPEN";
  const nParts = 1 + Math.floor(rnd() * 2);
  const parts = [];
  for (let p = 0; p < nParts; p++) {
    const c = pick(partCatalog);
    if (!parts.some(x => x.part_number === c.part_number))
      parts.push({ part_number: c.part_number, quantity: 1 + Math.floor(rnd() * 3), unit_cost_usd: c.unit_cost_usd });
  }
  batch.push({
    wo_number: "WO-" + (100000 + i),
    equipment_tag: pick(tags),
    wo_type: pick(["PREVENTIVE", "CORRECTIVE", "INSPECTION", "EMERGENCY"]),
    priority: 1 + Math.floor(rnd() * 4),
    status: status,
    raised_at: raised,
    downtime_hours: Math.round(rnd() * 600) / 10,
    assignments: [ { technician: pick(techs), role: "LEAD", hours: 2 + Math.floor(rnd() * 20) } ],
    parts: parts
  });
  if (batch.length === 2000) { ndfs.work_orders.insertMany(batch); batch = []; }
}
print("work_orders: " + ndfs.work_orders.countDocuments());

// ---------------- sensor_telemetry (every 10 minutes for 7 days on 4 machines = 4,032 readings) ----------------
const monitored = ["EKT-C-201", "OBG-C-201", "EKT-P-101", "OBG-P-101"];
const t0 = new Date("2026-11-01T00:00:00Z").getTime();
let readings = [];
for (const tag of monitored) {
  for (let k = 0; k < 7 * 24 * 6; k++) {
    // OBG-P-101 slowly develops a vibration problem (a failing seal/bearing): the story behind Q4 and Q5
    const drift = (tag === "OBG-P-101") ? k * 0.0045 : 0;
    readings.push({
      ts: new Date(t0 + k * 600000),
      meta: { tag: tag, station: tag.substring(0, 3) + "-FS" },
      vibration_mm_s: Math.round((2.5 + rnd() * 1.2 + drift) * 100) / 100,
      bearing_temp_c: Math.round((62 + rnd() * 6 + drift * 4) * 10) / 10,
      discharge_pressure_bar: Math.round((90 + rnd() * 8) * 10) / 10
    });
  }
}
ndfs.sensor_telemetry.insertMany(readings);
print("sensor_telemetry: " + ndfs.sensor_telemetry.countDocuments());
