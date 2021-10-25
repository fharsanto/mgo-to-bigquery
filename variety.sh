#!/bin/bash

# declare -a arr=("log_api_20200609" "log_api_20200610" "log_api_20200611" "log_api_20200612" "log_api_20200613" "log_api_20200615" "log_api_20200616" "log_api_20200617" "log_api_20200618" "log_api_20200619" "log_api_20200620" "log_api_20200621" "log_api_20200622" "log_api_20200623" "log_api_20200624" "log_api_20200625" "log_api_20200627" "log_api_20200629" "log_api_20200630" "log_api_20200705" "log_api_20200706" "log_api_20200707" "log_api_20200710" "log_api_20200713" "log_api_20200714" "log_api_20200715" "log_api_20200716" "log_api_20200720" "log_api_20200724" "log_api_20200725" "log_api_20200801" "log_api_20200803" "log_api_20200804" "log_api_20200805" "log_api_20200806" "log_api_20200807" "log_api_20200810" "log_api_20200811" "log_api_20200812" "log_api_20200813" "log_api_20200814" "log_api_20200815" "log_api_20200816" "log_api_20200817" "log_api_20200818" "log_api_20200824" "log_api_20200825" "log_api_20200826" "log_api_20200827" "log_api_20200828" "log_api_20200829" "log_api_20200830")
declare -a arr=("log_api_20200825" "log_api_20200826" "log_api_20200827" "log_api_20200828" "log_api_20200829" "log_api_20200830")
for i in "${arr[@]}"
do
   echo "$i\n"
   mongo --quiet databaseName --eval "var collection = '$i', outputFormat='json'" ../variety/variety.js > "$i.schema.json"
done