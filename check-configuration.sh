#!/bin/bash

# Check docker-compose configuration exists
docker-compose config -q || { echo -e "\033[1;31mError: docker-compose configuration is not valid\033[0m"; exit 1; }

# Check if .env file exists
[ -f .env ] || { echo -e "\033[1;31mError: .env file is missing\033[0m"; exit 1; }

# Extract all ports with their corresponding lines
ports=$(grep -nE '^\s*\w*PORT\w*\s*=\s*[0-9]+' .env)

# Extract only the port values
duplicate_ports=$(echo "$ports" | awk -F'=' '{print $2}' | tr -d ' ' | sort | uniq -d)

# Check if there are duplicate ports in .env
if [ -n "$duplicate_ports" ]; then
    echo -e "\033[1;31mError: Duplicate ports found in .env file:\033[0m"

    # Loop through each duplicate port and find its occurrences in the file
    while read -r port; do
        echo -e "\033[1;33mPort: $port found in:\033[0m"
        echo -e "\033[1;33m$ports\033[0m" | grep -w "$port"
    done <<< "$duplicate_ports"

    exit 1
fi

# Extract the values of CONSUMER_PDC_PORT and PROVIDER_PDC_PORT
expected_consumer_port=$(echo "$ports" | grep 'CONSUMER_PDC_PORT' | awk -F'=' '{print $2}' | tr -d ' ')
expected_provider_port=$(echo "$ports" | grep 'PROVIDER_PDC_PORT' | awk -F'=' '{print $2}' | tr -d ' ')
expected_infrastructure_port=$(echo "$ports" | grep 'INFRASTRUCTURE_PDC_PORT' | awk -F'=' '{print $2}' | tr -d ' ')

# Check if the extracted values match the expected values
consumer_pdc_port=$(grep 'PORT=' ./images/consumer-pdc/.env.production | awk -F'=' '{print $2}' | tr -d ' ')
provider_pdc_port=$(grep 'PORT=' ./images/provider-pdc/.env.production | awk -F'=' '{print $2}' | tr -d ' ')
infrastructure_pdc_port=$(grep 'PORT=' ./images/infrastructure-pdc/.env.production | awk -F'=' '{print $2}' | tr -d ' ')

#check if value in .env match value in .env.production for the connectors
if [ "$consumer_pdc_port" -ne "$expected_consumer_port" ]; then
    echo -e "\033[1;34mOverwriting PORT value in ./images/consumer-pdc/.env.production with $expected_consumer_port\033[0m"
    sed -i "s/PORT=.*$/PORT=$expected_consumer_port/" ./images/consumer-pdc/.env.production
fi

if [ "$provider_pdc_port" -ne "$expected_provider_port" ]; then
    echo -e "\033[1;34mOverwriting PORT value in ./images/provider-pdc/.env.production with $expected_provider_port\033[0m"
    sed -i "s/PORT=.*$/PORT=$expected_provider_port/" ./images/provider-pdc/.env.production
fi

if [ "$infrastructure_pdc_port" -ne "$expected_infrastructure_port" ]; then
    echo -e "\033[1;34mOverwriting PORT value in ./images/infrastructure-pdc/.env.production with $expected_infrastructure_port\033[0m"
    sed -i "s/PORT=.*$/PORT=$expected_infrastructure_port/" ./images/infrastructure-pdc/.env.production
fi

#retrieve the URI
# Retrieve the CONSENT_PORT and CONSENT_API_PREFIX from the .env file
extract_port() {
    local var_name=$1
    local port=$(grep "${var_name}=" .env | awk -F'=' '{print $2}' | tr -d ' ')
    port=${port%\"}
    port=${port#\"}
    echo "$port"
}

consent_port=$(extract_port 'CONSENT_BINDING_PORT')
consent_api_prefix=$(extract_port 'CONSENT_API_PREFIX')
catalog_port=$(extract_port 'CATALOG_BINDING_PORT')
catalog_api_port=$(extract_port 'CATALOG_API_PREFIX')
contract_port=$(extract_port 'CONTRACT_BINDING_PORT')
consumer_port=$(extract_port 'CONSUMER_PDC_BINDING_PORT')
provider_port=$(extract_port 'PROVIDER_PDC_BINDING_PORT')
infrastructure_port=$(extract_port 'INFRASTRUCTURE_PDC_BINDING_PORT')
provider_database=$(extract_port 'PROVIDER_PDC_DATABASE')
consumer_database=$(extract_port 'CONSUMER_PDC_DATABASE')
infrastructure_database=$(extract_port 'INFRASTRUCTURE_PDC_DATABASE')
provider_api_port=$(extract_port 'PROVIDER_API_PORT')
provider_api_database=$(extract_port 'PROVIDER_API_DATABASE')
consumer_api_port=$(extract_port 'CONSUMER_API_PORT')
consumer_api_database=$(extract_port 'CONSUMER_API_DATABASE')
infrastructure_api_port=$(extract_port 'INFRASTRUCTURE_API_PORT')
infrastructure_api_database=$(extract_port 'INFRASTRUCTURE_API_DATABASE')
general_uri=$(extract_port 'GENERAL_URI')

mongodb=$(extract_port 'MONGODB_DOCKER_NAME')
mongodb_port=$(extract_port 'MONGODB_DOCKER_PORT')

contract=$(extract_port 'CONTRACT_DOCKER_NAME')
consent=$(extract_port 'CONSENT_DOCKER_NAME')
catalog=$(extract_port 'CATALOG_DOCKER_NAME')
provider=$(extract_port 'PROVIDER_DOCKER_NAME')
consumer=$(extract_port 'CONSUMER_DOCKER_NAME')
infrastructure=$(extract_port 'INFRASTRUCTURE_DOCKER_NAME')

# Construct the expected consentUri
expected_consent_uri="http://$general_uri:$consent_port"
if [ -n "$consent_api_prefix" ]; then
  if [[ "$consent_api_prefix" != /* ]]; then
    expected_consent_uri+="/$consent_api_prefix"
  else
    expected_consent_uri+="$consent_api_prefix"
  fi
fi

# Construct the expected catalogUri
expected_catalog_uri="http://$general_uri:$catalog_port"
if [ -n "$catalog_api_port" ]; then
  if [[ "$catalog_api_port" != /* ]]; then
    expected_catalog_uri+="/$catalog_api_port"
  else
    expected_catalog_uri+="$catalog_api_port"
  fi
fi

# Construct the expected catalogUri
expected_contract_uri="http://$general_uri:$contract_port"

# Construct the expected catalogUri
expected_consumer_endpoint_uri="http://$general_uri:$consumer_port/"
expected_provider_endpoint_uri="http://$general_uri:$provider_port/"
expected_infrastructure_endpoint_uri="http://$general_uri:$infrastructure_port/"
expected_provider_mongo_uri="mongodb://$mongodb:$mongodb_port/$provider_database"
expected_consumer_mongo_uri="mongodb://$mongodb:$mongodb_port/$consumer_database"
expected_infrastructure_mongo_uri="mongodb://$mongodb:$mongodb_port/$infrastructure_database"
expected_provider_api_mongo_uri="mongodb://$mongodb:$mongodb_port/$provider_api_database"
expected_consumer_api_mongo_uri="mongodb://$mongodb:$mongodb_port/$consumer_api_database"
expected_infrastructure_api_mongo_uri="mongodb://$mongodb:$mongodb_port/$infrastructure_api_database"

# Check if the consentUri matches the expected format
actual_consumer_consent_uri=$(grep '"consentUri"' ./images/consumer-pdc/config.production.json | awk -F'"' '{print $4}')
actual_consumer_catalog_uri=$(grep '"catalogUri"' ./images/consumer-pdc/config.production.json | awk -F'"' '{print $4}')
actual_consumer_contract_uri=$(grep '"contractUri"' ./images/consumer-pdc/config.production.json | awk -F'"' '{print $4}')
actual_consumer_endpoint_uri=$(grep '"endpoint"' ./images/consumer-pdc/config.production.json | awk -F'"' '{print $4}')
actual_consumer_mongodb_uri=$(grep "MONGO_URI=" ./images/consumer-pdc/.env.production | awk -F'=' '{print $2}' | tr -d ' ')

# Check if the consentUri matches the expected format
actual_provider_consent_uri=$(grep '"consentUri"' ./images/provider-pdc/config.production.json | awk -F'"' '{print $4}')
actual_provider_catalog_uri=$(grep '"catalogUri"' ./images/provider-pdc/config.production.json | awk -F'"' '{print $4}')
actual_provider_contract_uri=$(grep '"contractUri"' ./images/provider-pdc/config.production.json | awk -F'"' '{print $4}')
actual_provider_endpoint_uri=$(grep '"endpoint"' ./images/provider-pdc/config.production.json | awk -F'"' '{print $4}')
actual_provider_mongodb_uri=$(grep "MONGO_URI=" ./images/provider-pdc/.env.production | awk -F'=' '{print $2}' | tr -d ' ')

# Check if the consentUri matches the expected format
actual_infrastructure_consent_uri=$(grep '"consentUri"' ./images/infrastructure-pdc/config.production.json | awk -F'"' '{print $4}')
actual_infrastructure_catalog_uri=$(grep '"catalogUri"' ./images/infrastructure-pdc/config.production.json | awk -F'"' '{print $4}')
actual_infrastructure_contract_uri=$(grep '"contractUri"' ./images/infrastructure-pdc/config.production.json | awk -F'"' '{print $4}')
actual_infrastructure_endpoint_uri=$(grep '"endpoint"' ./images/infrastructure-pdc/config.production.json | awk -F'"' '{print $4}')
actual_infrastructure_mongodb_uri=$(grep "MONGO_URI=" ./images/infrastructure-pdc/.env.production | awk -F'=' '{print $2}' | tr -d ' ')

#eexample-api
actual_infrastructure_api_mongodb_uri=$(grep "MONGO_URI=" ./images/example-api/.env.infrastructure | awk -F'=' '{print $2}' | tr -d ' ')
actual_provider_api_mongodb_uri=$(grep "MONGO_URI=" ./images/example-api/.env.provider | awk -F'=' '{print $2}' | tr -d ' ')
actual_consumer_api_mongodb_uri=$(grep "MONGO_URI=" ./images/example-api/.env.consumer | awk -F'=' '{print $2}' | tr -d ' ')
actual_infrastructure_api_port=$(grep "PORT=" ./images/example-api/.env.infrastructure | awk -F'=' '{print $2}' | tr -d ' ')
actual_consumer_api_port=$(grep "PORT=" ./images/example-api/.env.consumer | awk -F'=' '{print $2}' | tr -d ' ')
actual_provider_api_port=$(grep "PORT=" ./images/example-api/.env.provider | awk -F'=' '{print $2}' | tr -d ' ')

if [ "$actual_consumer_consent_uri" != "$expected_consent_uri" ]; then
    echo -e "\033[1;34mUpdating consentUri in ./images/consumer-pdc/config.production.json to match expected format:$expected_consent_uri\033[0m"
    sed -i "s|\"consentUri\":.*|\"consentUri\": \"$expected_consent_uri\",|" ./images/consumer-pdc/config.production.json
fi

if [ "$actual_consumer_catalog_uri" != "$expected_catalog_uri" ]; then
    echo -e "\033[1;34mUpdating catalogUri in ./images/consumer-pdc/config.production.json to match expected format:$expected_catalog_uri\033[0m"
    sed -i "s|\"catalogUri\":.*|\"catalogUri\": \"$expected_catalog_uri\",|" ./images/consumer-pdc/config.production.json
fi

if [ "$actual_consumer_contract_uri" != "$expected_contract_uri" ]; then
    echo -e "\033[1;34mUpdating contractUri in ./images/consumer-pdc/config.production.json to match expected format:$expected_contract_uri\033[0m"
    sed -i "s|\"contractUri\":.*|\"contractUri\": \"$expected_contract_uri\",|" ./images/consumer-pdc/config.production.json
fi

if [ "$actual_consumer_endpoint_uri" != "$expected_consumer_endpoint_uri" ]; then
    echo -e "\033[1;34mUpdating endpoint in ./images/consumer-pdc/config.production.json to match expected format:$expected_consumer_endpoint_uri\033[0m"
    sed -i "s|\"endpoint\":.*|\"endpoint\": \"$expected_consumer_endpoint_uri\",|" ./images/consumer-pdc/config.production.json
fi

if [ "$actual_consumer_mongodb_uri" != "$expected_consumer_mongo_uri" ]; then
    echo -e "\033[1;34mUpdating MONGO_URI in ./images/consumer-pdc/.env.production to match expected format:$expected_consumer_mongo_uri\033[0m"
    sed -i "s|MONGO_URI=.*$|MONGO_URI=$expected_consumer_mongo_uri|" ./images/consumer-pdc/.env.production
fi


if [ "$actual_provider_consent_uri" != "$expected_consent_uri" ]; then
    echo -e "\033[1;34mUpdating consentUri in ./images/provider-pdc/config.production.json to match expected format:$expected_consent_uri\033[0m"
    sed -i "s|\"consentUri\":.*|\"consentUri\": \"$expected_consent_uri\",|" ./images/provider-pdc/config.production.json
fi

if [ "$actual_provider_catalog_uri" != "$expected_catalog_uri" ]; then
    echo -e "\033[1;34mUpdating catalogUri in ./images/provider-pdc/config.production.json to match expected format:$expected_catalog_uri\033[0m"
    sed -i "s|\"catalogUri\":.*|\"catalogUri\": \"$expected_catalog_uri\",|" ./images/provider-pdc/config.production.json
fi

if [ "$actual_provider_contract_uri" != "$expected_contract_uri" ]; then
    echo -e "\033[1;34mUpdating contractUri in ./images/provider-pdc/config.production.json to match expected format:$expected_contract_uri\033[0m"
    sed -i "s|\"contractUri\":.*|\"contractUri\": \"$expected_contract_uri\",|" ./images/provider-pdc/config.production.json
fi

if [ "$actual_provider_endpoint_uri" != "$expected_provider_endpoint_uri" ]; then
    echo -e "\033[1;34mUpdating endpoint in ./images/provider-pdc/config.production.json to match expected format:$expected_provider_endpoint_uri\033[0m"
    sed -i "s|\"endpoint\":.*|\"endpoint\": \"$expected_provider_endpoint_uri\",|" ./images/provider-pdc/config.production.json
fi

if [ "$actual_provider_mongodb_uri" != "$expected_provider_mongo_uri" ]; then
    echo -e "\033[1;34mUpdating MONGO_URI in ./images/provider-pdc/.env.production to match expected format:$expected_provider_mongo_uri\033[0m"
    sed -i "s|MONGO_URI=.*$|MONGO_URI=$expected_provider_mongo_uri|" ./images/provider-pdc/.env.production
fi


if [ "$actual_infrastructure_consent_uri" != "$expected_consent_uri" ]; then
    echo -e "\033[1;34mUpdating consentUri in ./images/infrastructure-pdc/config.production.json to match expected format:$expected_consent_uri\033[0m"
    sed -i "s|\"consentUri\":.*|\"consentUri\": \"$expected_consent_uri\",|" ./images/infrastructure-pdc/config.production.json
fi

if [ "$actual_infrastructure_catalog_uri" != "$expected_catalog_uri" ]; then
    echo -e "\033[1;34mUpdating catalogUri in ./images/infrastructure-pdc/config.production.json to match expected format:$expected_catalog_uri\033[0m"
    sed -i "s|\"catalogUri\":.*|\"catalogUri\": \"$expected_catalog_uri\",|" ./images/infrastructure-pdc/config.production.json
fi

if [ "$actual_infrastructure_contract_uri" != "$expected_contract_uri" ]; then
    echo -e "\033[1;34mUpdating contractUri in ./images/infrastructure-pdc/config.production.json to match expected format:$expected_contract_uri\033[0m"
    sed -i "s|\"contractUri\":.*|\"contractUri\": \"$expected_contract_uri\",|" ./images/infrastructure-pdc/config.production.json
fi

if [ "$actual_infrastructure_endpoint_uri" != "$expected_infrastructure_endpoint_uri" ]; then
    echo -e "\033[1;34mUpdating endpoint in ./images/infrastructure-pdc/config.production.json to match expected format:$expected_infrastructure_endpoint_uri\033[0m"
    sed -i "s|\"endpoint\":.*|\"endpoint\": \"$expected_infrastructure_endpoint_uri\",|" ./images/infrastructure-pdc/config.production.json
fi

if [ "$actual_infrastructure_mongodb_uri" != "$expected_infrastructure_mongo_uri" ]; then
    echo -e "\033[1;34mUpdating MONGO_URI in ./images/infrastructure-pdc/.env.production to match expected format:$expected_infrastructure_mongo_uri\033[0m"
    sed -i "s|MONGO_URI=.*$|MONGO_URI=$expected_infrastructure_mongo_uri|" ./images/infrastructure-pdc/.env.production
fi

# example-api
if [ "$provider_api_port" != "$actual_provider_api_port" ]; then
    echo -e "\033[1;34mUpdating PORT in ./images/example-api/.env.provider to match expected format:$provider_api_port\033[0m"
    sed -i "s|PORT=.*$|PORT=$provider_api_port|" ./images/example-api/.env.provider
fi
if [ "$actual_provider_api_mongodb_uri" != "$expected_provider_api_mongo_uri" ]; then
    echo -e "\033[1;34mUpdating MONGO_URI in ./images/example-api/.env.provider to match expected format:$expected_provider_api_mongo_uri\033[0m"
    sed -i "s|MONGO_URI=.*$|MONGO_URI=$expected_provider_api_mongo_uri|" ./images/example-api/.env.provider
fi

if [ "$consumer_api_port" != "$actual_consumer_api_port" ]; then
    echo -e "\033[1;34mUpdating PORT in ./images/example-api/.env.consumer to match expected format:$consumer_api_port\033[0m"
    sed -i "s|PORT=.*$|PORT=$consumer_api_port|" ./images/example-api/.env.consumer
fi
if [ "$actual_consumer_api_mongodb_uri" != "$expected_consumer_api_mongo_uri" ]; then
    echo -e "\033[1;34mUpdating MONGO_URI in ./images/example-api/.env.consumer to match expected format:$expected_consumer_api_mongo_uri\033[0m"
    sed -i "s|MONGO_URI=.*$|MONGO_URI=$expected_consumer_api_mongo_uri|" ./images/example-api/.env.consumer
fi

if [ "$infrastructure_api_port" != "$actual_infrastructure_api_port" ]; then
    echo -e "\033[1;34mUpdating PORT in ./images/example-api/.env.infrastructure to match expected format:$infrastructure_api_port\033[0m"
    sed -i "s|PORT=.*$|PORT=$infrastructure_api_port|" ./images/example-api/.env.infrastructure
fi
if [ "$actual_infrastructure_api_mongodb_uri" != "$expected_infrastructure_api_mongo_uri" ]; then
    echo -e "\033[1;34mUpdating MONGO_URI in ./images/example-api/.env.infrastructure to match expected format:$expected_infrastructure_api_mongo_uri\033[0m"
    sed -i "s|MONGO_URI=.*$|MONGO_URI=$expected_infrastructure_api_mongo_uri|" ./images/example-api/.env.infrastructure
fi

echo -e "✅ \033[1;32m Configuration check passed\033[0m"