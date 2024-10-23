Step 1: Create index_pattern
```
PUT http://192.168.0.24:9200/qa-test-case-logs


{
  "mappings": {
    "properties": {
      "start_time": {
        "type": "date"
      },
      "test_id": {
        "type": "keyword"
      },
      "scenario": {
        "type": "text"
      },
      "end_time": {
        "type": "date"
      },
      "status": {
        "type": "keyword"
      },
      "author": {
        "type": "keyword"
      }
    }
  }
}
```

Step 2: Create data View
Kibanna -> Stack Management -> Data Views -> Create Data View

Step 3:
Kibanna -> Dev Tools -> Console and run below

```
PUT /_ingest/pipeline/add-timestamp-pipeline
{
  "description": "Pipeline to add start_time and end_time",
  "processors": [
    {
      "set": {
        "field": "start_time",
        "value": "{{_ingest.timestamp}}"
      }
    },
    {
      "set": {
        "field": "end_time",
        "value": "{{_ingest.timestamp}}"
      }
    }
  ]
}
```


Step 4: 
```
POST http://192.168.0.24:9200/qa-test-case-logs/_doc?pipeline=add-timestamp-pipeline

{
  "test_id": "QA-2",
  "scenario": "Verify if user is able to login with operator user",
  "status": "FAIL",
  "author": "user_1"
}
```

Step 5: Create Dashboard
