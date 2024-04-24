# aws-sns-subscription-policy

```sh
aws sns publish \
    --topic-arn "$(terraform output -raw topic_arn)" \
    --message-attributes '{"source":{"DataType":"String","StringValue":"aaa"}}' \
    --message '{"message":"source:aaa"}'

aws sns publish \
    --topic-arn "$(terraform output -raw topic_arn)" \
    --message-attributes '{"source":{"DataType":"String.Array","StringValue":"[\"aaa\"]"}}' \
    --message '{"message":"source:[aaa]"}'

aws sns publish \
    --topic-arn "$(terraform output -raw topic_arn)" \
    --message-attributes '{"source":{"DataType":"String.Array","StringValue":"[\"bbb\"]"}}' \
    --message '{"message":"source:[bbb]"}'

aws sns publish \
    --topic-arn "$(terraform output -raw topic_arn)" \
    --message-attributes '{"source":{"DataType":"String.Array","StringValue":"[\"ccc\"]"}}' \
    --message '{"message":"source:[ccc]"}'

aws sns publish \
    --topic-arn "$(terraform output -raw topic_arn)" \
    --message-attributes '{"source":{"DataType":"String.Array","StringValue":"[\"aaa\",\"bbb\"]"}}' \
    --message '{"message":"source:[aaa,bbb]"}'

aws sns publish \
    --topic-arn "$(terraform output -raw topic_arn)" \
    --message-attributes '{"source":{"DataType":"String.Array","StringValue":"[\"aaa\",\"ccc\"]"}}' \
    --message '{"message":"source:[aaa,ccc]"}'
```
