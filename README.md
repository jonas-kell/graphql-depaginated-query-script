# Graphql depaginated-query Script

`graphql-depaginated-query-script` (`gdqs`).

A simple single-script-dependency that simplifies running graphql-queries from the command line (for example in CICD Pipelines) against an endpoint that provides paginated data.
While queries can simply be run against the endpoint with [curl](https://curl.se/), it is rather complicated to accumulate the queried results into a single json output if the resource returns the data paginated.

# Dependencies and Installation

This script can simply be used as-is. Just `curl` it into the folder that you want to run the commands in.
It uses [Bash](https://www.gnu.org/software/bash/) syntax and requires the executables for [curl](https://curl.se/) and [jq](https://stedolan.github.io/jq/) to be available.

```cmd
curl https://raw.githubusercontent.com/jonas-kell/graphql-depaginated-query-script/master/gdqs.sh --output gdqs.sh
chmod +x gdgs.sh
```

# Configuration

For generating the necessary queries and jq configurations it can be recommended to use the GrapiQL endpoint of the service you are using (example for [Gitlab](https://gitlab.com/-/graphql-explorer)), as well as the [jq-playground](https://jqplay.org/).

As an example we are going to de-paginate the commits that belong to a specific project's merge-request in Gitlab.

## General Configuration

In order to set the script up to succeed, the required environemnt variables need to be set in the execution context.
Here the values that need to be replaced is everything insite and including the `<<...>>`.
The second half of the `<<...|...>>` gives an example for using the script in a Gitlab CICD pipeline.

```cmd
export GDQS_ENDPOINT_URL=<<URL to the qraphql api|"$CI_SERVER_URL/api/graphql">>
export GDQS_BEARER_TOKEN=<<Authorization token that grants access|"$GITLAB_API_ACCESS_TOKEN">> #(For Gitlab bind a custom secret-CICD-variable with a token with api-read access to $GITLAB_API_ACCESS_TOKEN or any other variable name of your chosing)
export GDQS_JQ_OUTPUT_FILTER=<<Filter to let jq filter out unnecessary parts of the output|".[][][][].nodes">>
```

## Non-paginated Output

```cmd
export GDQS_GRAPHQL_QUERY_STRING=<<The Query that gets sent to the endpoint|"{\"query\": \"query{project(fullPath:\\\"$CI_PROJECT_PATH\\\"){mergeRequest(iid:\\\"$CI_MERGE_REQUEST_IID\\\"){commits{nodes{shortId,fullTitle}}}}}\"}">>
export GDQS_JQ_END_CURSOR_FILTER="" # Explained below, not needed in this case
export GDQS_JQ_HAS_NEXT_PAGE_FILTER="false" # Explained below should always return false if no pagination is wanted
```

## Paginated Output

A loop will iterate over the queries while the `$GDQS_CURRENT_AFTER_VALUE` is set new every time.
In the query string, this variable needs to be escaped, so it can be inserted every iteration.
The other variables in the example can be evaluated the first time, because they are known from the beginning and do not change.

```cmd
export GDQS_GRAPHQL_QUERY_STRING=<<Query with the $GDQS_CURRENT_AFTER_VALUE at the right place|"{\"query\": \"query{project(fullPath:\\\"$CI_PROJECT_PATH\\\"){mergeRequest(iid:\\\"$CI_MERGE_REQUEST_IID\\\"){commits(after:\\\"\$GDQS_CURRENT_AFTER_VALUE\\\"){nodes{shortId,fullTitle},pageInfo{endCursor,hasNextPage}}}}}\"}">>
export GDQS_JQ_END_CURSOR_FILTER=<<jq instruction to parse the endCursor variable from the curl output|".[][][][].pageInfo.endCursor">>
export GDQS_JQ_HAS_NEXT_PAGE_FILTER=<<jq instruction to parse the hasNextPage variable from the curl output|".[][][][].pageInfo.hasNextPage">>
```

## Example JSON for the jq-play editor for the Gitlab example

```json
{
    "data": {
        "project": {
            "mergeRequest": {
                "commits": {
                    "nodes": [
                        {
                            "shortId": "bah617fe",
                            "fullTitle": "chore: a commit"
                        },
                        {
                            "shortId": "75d9s3f6",
                            "fullTitle": "fix: an other commit"
                        }
                    ],
                    "pageInfo": {
                        "endCursor": "MTAw",
                        "hasNextPage": true
                    }
                }
            }
        }
    }
}
```

## Example explanation on how the output after the filter should look

First call:

```json
[
    {
        "shortId": "bah617fe",
        "fullTitle": "chore: a commit"
    },
    {
        "shortId": "75d9s3f6",
        "fullTitle": "fix: an other commit"
    }
]
```

Second call:

```json
[
    {
        "shortId": "a987ha0a",
        "fullTitle": "doc: commits"
    },
    {
        "shortId": "bceha0a7",
        "fullTitle": "fix: final commit"
    }
]
```

What will be produced by the script as final output: (Behaviour can be altered, using the `$GDQS_JQ_ARRAY_MERGER_FILTER` variable)

```json
[
    {
        "shortId": "bah617fe",
        "fullTitle": "chore: a commit"
    },
    {
        "shortId": "75d9s3f6",
        "fullTitle": "fix: an other commit"
    },
    {
        "shortId": "a987ha0a",
        "fullTitle": "doc: commits"
    },
    {
        "shortId": "bceha0a7",
        "fullTitle": "fix: final commit"
    }
]
```
