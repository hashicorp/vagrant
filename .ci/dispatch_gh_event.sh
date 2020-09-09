echo "Dispatching github actions event"
curl -X POST ${TARGET_URL} \
-H 'Accept: application/vnd.github.everest-v3+json' \
-u $HASHIBOT_USERNAME:$HASHIBOT_TOKEN \
--data '{ "event_type": "'"${EVENT_TYPE}"'" }'
