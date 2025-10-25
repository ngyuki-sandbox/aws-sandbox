
send: input_queue_url=$(shell terraform output -raw input_queue_url 2>/dev/null)
send:
	aws sqs send-message --queue-url ${input_queue_url} --message-attributes '{"source":{"StringValue":"test","DataType":"String"}}' --message-body '{"id":"123"}'

logs: log_group_name=$(shell terraform output -raw log_group_name 2>/dev/null)
logs:
	aws logs tail ${log_group_name} --follow

recv: output_queue_url=$(shell terraform output -raw output_queue_url 2>/dev/null)
recv:
	aws sqs receive-message --queue-url ${output_queue_url} --wait-time-seconds 20 --max-number-of-messages 10 --message-attribute-names All
