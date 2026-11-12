// Portfolio 5: SHARDING reference (design evidence)
// Atlas M0/free tiers and a single replica set do NOT support sharding, so this script is meant for a
// sharded cluster (Atlas M30+, or a local sharded docker setup). Do not present its output as run results unless you ran it.
// It records the design decision and the exact commands.
//
// sh.enableSharding("ndfs_nosql")
//
// 1) Telemetry: compound shard key {meta.tag: 1, ts: 1}
//    - queries almost always filter by machine tag and a time window -> targeted to one or few shards
//    - writes spread across machines (many tags) instead of hammering one "latest time" chunk
//    - a key on ts alone would be MONOTONICALLY INCREASING: all new writes go to one shard (hot shard)
// sh.shardCollection("ndfs_nosql.sensor_telemetry", { "meta.tag": 1, ts: 1 })
//
// 2) Work orders: hashed key on equipment_tag, even distribution, equality lookups by tag stay targeted
// sh.shardCollection("ndfs_nosql.work_orders", { equipment_tag: "hashed" })
//
// 3) Zone sharding for data locality (region-based, like GlobalCare's horizontal fragmentation by country):
//    key must include the region. Example for equipment_specs: { "station.region": 1, tag_number: 1 }
// sh.addShardToZone("shardEast", "ONSHORE_EAST")
// sh.updateZoneKeyRange("ndfs_nosql.equipment_specs",
//     { "station.region": "ONSHORE_EAST", tag_number: MinKey }, { "station.region": "ONSHORE_EAST", tag_number: MaxKey }, "ONSHORE_EAST")
//
// Inspect: sh.status()   and   db.sensor_telemetry.getShardDistribution()
print("Reference file: read the comments. Commands are intentionally commented out.");
