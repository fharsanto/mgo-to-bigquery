# BigQuery migration step
This guidence purpose is for importing MongoDB collections to BigQuery tables.

## Analyze MongoDB collection
Analyze the collection structure for checking which field is consistent occurs in collections. For this things i'm using [Variety](https://github.com/variety/variety) 

Syntax command is quite straight forward
```
mongo --quiet YourDatabaseName --eval "var collection = 'YourCollectionName', outputFormat='json'" variety.js > YourPathFileForExportingResult
```

Here's the sample output of variety command

| key                       | types                     | occurrences | percents|
| ------------------------- | ------------------------- | ----------- | ------- |
| _id                       | ObjectId                  |       22898 | 100.000 |
| datetime                  | Date                      |       22898 | 100.000 |
| log_data                  | Object                    |       22898 | 100.000 |
| log_data.client_ip        | String                    |       22898 | 100.000 |
| log_data.typeService      | String                    |       22176 |  96.846 |
| log_data.clientStatus     | String (765),null (4)     |         769 |   3.358 |
| log_data.clientMessage    | String (27),Boolean (4)   |          31 |   0.135 |
| log_data.clientTrx_amount | String (25),Number (2)    |          27 |   0.117 |
| log_data.clientDebit_no   | String                    |          15 |   0.065 |
| log_data.clientVA         | String                    |           7 |   0.030 |

From this output analysis, there's few inconsistent field / data. 

Wait it for a minutes!!! It's only for one collection, what about 52 collections?
Hmm, must do 52x variety command and after that we must find average of occurrences in 52 collections. How do we find that kind of data? [Jupyter Notebook](https://jupyter.org/) and python came to rescue.

Here's the output of the Notebook
```
_id                                                              100.000000
datetime                                                         100.000000
log_data                                                         100.000000
log_data.clientEncryptedResponse                                 100.000000
log_data.client_ip                                               100.000000
log_data.domainInfo                                              100.000000
log_data.domainInfo.QUERY_STRING                                 100.000000
log_data.domainInfo.REQUEST_URI                                  100.000000
log_data.clientRequest                                            96.556530
log_data.clientRequest.client_id                                  94.595411
log_data.clientEncryptedResponse.data                             69.757025
```
Apparently our analysis within single collection is represents of 52 collections.

### Preparing the data
Exporting all collection to json format, we can loop this format command within bash script, it's using js file because we need rid or formatting the column, like `_id` or `transport_id` (because the type is ObjectId)

```
mongo --quiet bni_collection_log --eval "var tableName = '$i'" aggr.js > pathOfJsonFile
```

After that, we must get rid of bracket array (thanks to [jq](https://stedolan.github.io/jq/) for helping this things out), and replace to newline format based on google json format, see [this](https://cloud.google.com/bigquery/docs/loading-data-cloud-storage-json) and [this](https://cloud.google.com/blog/products/bigquery/inside-capacitor-bigquerys-next-generation-columnar-storage-format)

```
cat pathOfYourJsonFile | jq -c '.[]' > outputYourJsonFile
```

After that we merge all 52 json exported data to single file json
```
cat *.json > pathMergeJsonFile
```

### Preparing the schema table in BigQuery
Based on previous [section](#preparing-the-data), we can define which field more occurs. But because the response data is not consistence, we can store unconsistence data to string json, for this things we need 2 tables, raw data and real data tables.
1. raw data
```
[{
"name": "data",
"type": "STRING"
}]
```
In this table we can restore row per row json as string json

2. real data
[schema](schema_.json)
After restore we can insert select from raw data table

### Importing data to BigQuery tables
Because local data source limitation cannot exced 10 MB, [see](https://cloud.google.com/bigquery/docs/batch-loading-data#limitations-local-files).
We must upload the file into google cloud storage.

In active data set, click new table button:
- Create table from: select Google cloud storage and select the json file
- File format: CSV, why? because we need insert all json string to field data
- Table name: insert `raw_data`
- Schema, click Edit as text, fill in the schema like in [prev section](#preparing-the-schema-table-in-bigquery)
- Advance Options
- Field delimiter: Custom
- Custom field delimiter: fill in with `%` because that char not found in the data
- Quoted newline: checked
- Jagged rows: checked
- Click Create table

### Restore data to real data table
Create empty table for real data.
In active data set, click new table button:
- Create table from: Empty table
- Table name: insert `real_data`
- Schema, click Edit as text, fill the schema with [this](schema_.json)
- Click Create table

After real_data created, execute this query:
```
INSERT `NameOfProject.NameOfDataSet.real_data`(datetime, service, transact_id, log_data)
SELECT
    TIMESTAMP(JSON_EXTRACT_SCALAR(data,'$.datetime')) AS datetime,
    JSON_EXTRACT_SCALAR(data,'$.service') AS service,
    JSON_EXTRACT_SCALAR(data,'$.transact_id') AS transact_id,
    STRUCT<snippet string, client_ip string, processTime string, server string,
    client_id string, prefix string, typeService string, virtual_account string,
    clientEncryptedResponse STRUCT<status string, message string, `data` string>,
    additionalError string, domainInfo STRUCT<QUERY_STRING string, REQUEST_URI string, 
    SERVER_ADDR string, SERVER_NAME string, SERVER_PORT string>, `error` string,
    clientResponse string, clientRequest string, clientParsedRequest string>
    (
      JSON_EXTRACT_SCALAR(data, '$.log_data.snippet'),
      JSON_EXTRACT_SCALAR(data, '$.log_data.client_ip'),
      JSON_EXTRACT_SCALAR(data, '$.log_data.processTime'),
      JSON_EXTRACT_SCALAR(data, '$.log_data.server'),
      JSON_EXTRACT_SCALAR(data, '$.log_data.client_id'),
      JSON_EXTRACT_SCALAR(data, '$.log_data.prefix'),
      JSON_EXTRACT_SCALAR(data, '$.log_data.typeService'),
      JSON_EXTRACT_SCALAR(data, '$.log_data.virtual_account'),
      (
        JSON_EXTRACT_SCALAR(data, '$.log_data.clientEncryptedResponse.status'),
        JSON_EXTRACT_SCALAR(data, '$.log_data.clientEncryptedResponse.message'),
        JSON_EXTRACT_SCALAR(data, '$.log_data.clientEncryptedResponse.data')
        ),
      JSON_EXTRACT_SCALAR(data, '$.log_data.additionalError'),
      (
        JSON_EXTRACT_SCALAR(data, '$.log_data.domainInfo.QUERY_STRING'),
        JSON_EXTRACT_SCALAR(data, '$.log_data.domainInfo.REQUEST_URI'),
        JSON_EXTRACT_SCALAR(data, '$.log_data.domainInfo.SERVER_NAME'),
        JSON_EXTRACT_SCALAR(data, '$.log_data.domainInfo.SERVER_ADDR'),
        JSON_EXTRACT_SCALAR(data, '$.log_data.domainInfo.SERVER_PORT')
      ),
      JSON_EXTRACT(data, '$.log_data.error'),
      JSON_EXTRACT(data, '$.log_data.clientResponse'),
      JSON_EXTRACT(data, '$.log_data.clientRequest'),
      JSON_EXTRACT(data, '$.log_data.clientParsedRequest')
    ) as log_data
FROM
  `NameOfProject.NameOfDataSet.raw_data`
```