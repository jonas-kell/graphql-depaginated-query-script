#!/bin/bash

while getopts v flag
do
    case "${flag}" in
        v) verbose=1;
    esac
done

if [ $verbose ] 
then 
    echo "GDQS querying the endpoint:";
fi
GDQS_JQ_ARRAY_MERGER_FILTER=${GDQS_JQ_ARRAY_MERGER_FILTER:="[.[0][],.[1][]]"};
GDQS_CURRENT_AFTER_VALUE=${GDQS_CURRENT_AFTER_VALUE:=""};
GDQS_CURRENT_HAS_NEXT_PAGE_VALUE=${GDQS_CURRENT_HAS_NEXT_PAGE_VALUE:="true"};

GDQS_FINAL_OUTPUT="[]";

while [ "$GDQS_CURRENT_HAS_NEXT_PAGE_VALUE" != "false" ]; do
    if [ $verbose ] 
    then 
        echo "GDQS is reading the next page";
    fi
    GDQS_CURL_RESPONSE=$(curl "$GDQS_ENDPOINT_URL" --header "Authorization: Bearer $GDQS_BEARER_TOKEN" --header "Content-Type: application/json" --request POST --data "${GDQS_GRAPHQL_QUERY_STRING//\$GDQS_CURRENT_AFTER_VALUE/$GDQS_CURRENT_AFTER_VALUE}");
    
    if [ $verbose ] 
    then 
        echo "GDQS is processing the response";  
    fi
    GDQS_FILTERED_RESPONSE=$(echo "$GDQS_CURL_RESPONSE" | jq -r "$GDQS_JQ_OUTPUT_FILTER");
    GDQS_CURRENT_AFTER_VALUE=$(echo "$GDQS_CURL_RESPONSE" | jq -r "$GDQS_JQ_END_CURSOR_FILTER");
    GDQS_CURRENT_HAS_NEXT_PAGE_VALUE=$(echo "$GDQS_CURL_RESPONSE" | jq -r "$GDQS_JQ_HAS_NEXT_PAGE_FILTER");
    
    if [ $verbose ] 
    then 
        echo "GDQS appends the values to the output";
    fi
    GDQS_FINAL_OUTPUT=$(echo "[$GDQS_FINAL_OUTPUT,$GDQS_FILTERED_RESPONSE]" | jq -r "$GDQS_JQ_ARRAY_MERGER_FILTER");
done

echo "$GDQS_FINAL_OUTPUT";
