# [Tech Spec] Handling Intermittent Request Failure

## Context

Converted quality measures data needs to be submitted via API to an external service. This external service has intermittent request failure. Thus our quality measure convert service must include some fault tolerance.

## Approach

The intermittent request failure implies that sending the converted data to the external service cannot be done syncronhously. Instead it must be handled in a background process that can monitor for failed requests and retry them. Originally, after data conversion is completed the script would make a request to the external service. Instead now, the script would push a message to a message queue. Services like [AWS SQS](https://aws.amazon.com/sqs/) or [RabbitMQ](https://www.rabbitmq.com/) can be used for the message queue. A separate process is needed that would pop messages off the queue, and process the relavant file. Each message would contain information like:

    {
      type: 'push_data_to_external_service',
      filename: 'quality_measures_2017_1234.json'
    }

Since the data is no longer being sent syncronously, it needs to be stored temporarily before being submitted to the external service. The easiest solution would be to take the JSON file that the script currently outputs, and to push it up to S3 for temporary storage. Then when the background process plucks the message off the queue, it could use the `filename` attribute to find the file on S3, read the contents, and submit it to the external service.

Services like AWS SQS have built in fault tolerance in that a "success response" must be sent to the message queue after completing the task. If this success response is not received within X seconds, the message is automatically re-added to the message queue to be retried. This ensures that even if the initial request to the service fails, the request will later be retried so no data is lost.
