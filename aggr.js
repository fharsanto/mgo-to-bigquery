data = db[tableName].aggregate([
  { $addFields: { transact_id: { $toString: "$transact_id" } } },
  { $project: { "_id": 0 } },
  // { $limit: 5000 }
]).toArray();

print(JSON.stringify(data));

// db.log_api_client_20200619.aggregate().toArray();