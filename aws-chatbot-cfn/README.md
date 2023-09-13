# chatbot / cloudformation / custom notifications

- https://docs.aws.amazon.com/chatbot/latest/adminguide/custom-notifs.html

```sh
aws sns publish --topic-arn "$TOPIC_ARN" --message '{
    "version": "1.0",
    "source": "custom",
    "content": {
        "description": ":warning: EC2 auto scaling refresh failed for ASG *OrderProcessorServiceASG*! \ncc: @SRE-Team"
    }
}'

aws sns publish --topic-arn "$TOPIC_ARN" --message '{
    "version": "1.0",
    "source": "custom",
    "id": "c-weihfjdsf",
    "content": {
      "textType": "client-markdown",
      "title": ":warning: Banana Order processing is down!",
      "description": "Banana Order processor application is no longer processing orders. OnCall team has beeen paged.",
      "nextSteps": [
        "Refer to <http://www.example.com|*diagnosis* runbook>",
        "@googlie: Page Jane if error persists over 30 minutes",
        "Check if instance i-04d231f25c18592ea needs to receive an AMI rehydration"
      ],
      "keywords": [
        "BananaOrderIntake",
        "Critical",
        "SRE"
      ]
    },
    "metadata": {
      "threadId": "OrderProcessing-1",
      "summary": "Order Processing Update",
      "eventType": "BananaOrderAppEvent",
      "relatedResources": [
        "i-04d231f25c18592ea",
        "i-0c8c31affab6078fb"
      ],
      "additionalContext": {
        "priority": "critical"
      }
    }
}'
```
