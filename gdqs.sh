#!/bin/bash

echo "GDQS querying the endpoint:";

GDQS_JQ_ARRAY_MERGER_FILTER=${GDQS_JQ_ARRAY_MERGER_FILTER:="[.[0][],.[1][]]"};
GDQS_CURRENT_AFTER_VALUE=${GDQS_CURRENT_AFTER_VALUE:=""};
GDQS_CURRENT_HAS_NEXT_PAGE_VALUE=${GDQS_CURRENT_HAS_NEXT_PAGE_VALUE:="true"};

GDQS_FINAL_OUTPUT="[]";

while [ "$GDQS_CURRENT_HAS_NEXT_PAGE_VALUE" != "false" ]; do
    echo "GDQS is reading the next page";
    echo "$GDQS_ENDPOINT_URL";
    GDQS_CURL_RESPONSE=$(curl "$GDQS_ENDPOINT_URL" --header "Authorization: Bearer $GDQS_BEARER_TOKEN" --header "Content-Type: application/json" --request POST --data "${GDQS_GRAPHQL_QUERY_STRING//\$GDQS_CURRENT_AFTER_VALUE/$GDQS_CURRENT_AFTER_VALUE}");
    
    echo "GDQS is processing the response";  
    GDQS_FILTERED_RESPONSE=$(echo "$GDQS_CURL_RESPONSE" | jq -r "$GDQS_JQ_OUTPUT_FILTER");
    GDQS_CURRENT_AFTER_VALUE=$(echo "$GDQS_CURL_RESPONSE" | jq -r "$GDQS_JQ_END_CURSOR_FILTER");
    GDQS_CURRENT_HAS_NEXT_PAGE_VALUE=$(echo "$GDQS_CURL_RESPONSE" | jq -r "$GDQS_JQ_HAS_NEXT_PAGE_FILTER");
    
    echo "GDQS appends the values to the output";
    GDQS_FINAL_OUTPUT=$(echo "[$GDQS_FINAL_OUTPUT,$GDQS_FILTERED_RESPONSE]" | jq -r "$GDQS_JQ_ARRAY_MERGER_FILTER");
done

echo "$GDQS_FINAL_OUTPUT";
