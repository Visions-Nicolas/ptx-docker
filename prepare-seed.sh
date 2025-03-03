#!/bin/bash
export $(grep -v '^#' .env | xargs) 

envsubst < ./images/mongodb-seed/template/catalog.representations.template.json > ./images/mongodb-seed/init/catalog.representations.json
envsubst < ./images/mongodb-seed/template/catalog.ecosystems.template.json > ./images/mongodb-seed/init/catalog.ecosystems.json
envsubst < ./images/mongodb-seed/template/catalog.serviceofferings.template.json > ./images/mongodb-seed/init/catalog.serviceofferings.json
envsubst < ./images/mongodb-seed/template/catalog.softwareresources.template.json > ./images/mongodb-seed/init/catalog.softwareresources.json
envsubst < ./images/mongodb-seed/template/consent.participants.template.json > ./images/mongodb-seed/init/consent.participants.json
envsubst < ./images/mongodb-seed/template/contract.contracts.template.json > ./images/mongodb-seed/init/contract.contracts.json

sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/catalog.representations.json
sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/catalog.ecosystems.json
sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/catalog.serviceofferings.json
sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/catalog.softwareresources.json
sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/consent.participants.json
sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/contract.contracts.json

# Find and replace "_id": {"" with "_id": {"$oid" in each file
for file in ./images/mongodb-seed/init/*.json; do
    sed -i 's/"_id": {""/"_id": {"$oid"/g' $file
    sed -i 's/"": /"$oid": /g' $file
done
