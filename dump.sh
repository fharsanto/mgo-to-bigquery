#!/bin/bash

declare -a arr=("log_api_client_20200609" "log_api_client_20200610" "log_api_client_20200611" "log_api_client_20200612" "log_api_client_20200613" "log_api_client_20200615" "log_api_client_20200616" "log_api_client_20200617" "log_api_client_20200618" "log_api_client_20200619" "log_api_client_20200620" "log_api_client_20200621" "log_api_client_20200622" "log_api_client_20200623" "log_api_client_20200624" "log_api_client_20200625" "log_api_client_20200627" "log_api_client_20200629" "log_api_client_20200630" "log_api_client_20200705" "log_api_client_20200706" "log_api_client_20200707" "log_api_client_20200710" "log_api_client_20200713" "log_api_client_20200714" "log_api_client_20200715" "log_api_client_20200716" "log_api_client_20200720" "log_api_client_20200724" "log_api_client_20200725" "log_api_client_20200801" "log_api_client_20200803" "log_api_client_20200804" "log_api_client_20200805" "log_api_client_20200806" "log_api_client_20200807" "log_api_client_20200810" "log_api_client_20200811" "log_api_client_20200812" "log_api_client_20200813" "log_api_client_20200814" "log_api_client_20200815" "log_api_client_20200816" "log_api_client_20200817" "log_api_client_20200818" "log_api_client_20200824" "log_api_client_20200825" "log_api_client_20200826" "log_api_client_20200827" "log_api_client_20200828" "log_api_client_20200829" "log_api_client_20200830")
# declare -a arr=("log_api_client_20200825" "log_api_client_20200826" "log_api_client_20200827" "log_api_client_20200828" "log_api_client_20200829" "log_api_client_20200830")
for i in "${arr[@]}"
do
   mongo --quiet bni_collection_log --eval "var tableName = '$i'" aggr.js > "data/$i.json"
   # if [ -s "data/$i.json" ]
   # then
   #    rm -f "data/$i.json"
   # else
   cat "data/$i.json" | jq -c '.[]' > "data/$i.rm.json"
   # fi
   echo "end exporting $i\n"
done