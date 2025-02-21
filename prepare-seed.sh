#!/bin/bash
export $(grep -v '^#' .env | xargs) 

envsubst < ./images/mongodb-seed/template/catalog.datarepresentations.template.json > ./images/mongodb-seed/init/catalog.datarepresentations.json
envsubst < ./images/mongodb-seed/template/catalog.ecosystems.template.json > ./images/mongodb-seed/init/catalog.ecosystems.json
envsubst < ./images/mongodb-seed/template/catalog.serviceofferings.template.json > ./images/mongodb-seed/init/catalog.serviceofferings.json
envsubst < ./images/mongodb-seed/template/catalog.softwarerepresentations.template.json > ./images/mongodb-seed/init/catalog.softwarerepresentations.json
envsubst < ./images/mongodb-seed/template/catalog.softwareresources.template.json > ./images/mongodb-seed/init/catalog.softwareresources.json
envsubst < ./images/mongodb-seed/template/consent.participants.template.json > ./images/mongodb-seed/init/consent.participants.json
envsubst < ./images/mongodb-seed/template/contract.contracts.template.json > ./images/mongodb-seed/init/contract.contracts.json

sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/catalog.datarepresentations.json
sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/catalog.ecosystems.json
sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/catalog.serviceofferings.json
sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/catalog.softwarerepresentations.json
sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/catalog.softwareresources.json
sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/consent.participants.json
sed -i 's/[\x00-\x1F]//g' ./images/mongodb-seed/init/contract.contracts.json
