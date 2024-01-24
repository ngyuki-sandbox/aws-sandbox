# aws-sns-subscription-policy

```sh
aws sns publish --topic-arn "$(terraform output -raw topic_arn)" --message '{"source":"oreore","message":"test"}'
aws sns publish --topic-arn "$(terraform output -raw topic_arn)" --message '{"source":"areare","message":"test"}'
```
