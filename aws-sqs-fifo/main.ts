import { ok } from 'assert';
import { SQSClient, ReceiveMessageCommand, SendMessageCommand, DeleteMessageCommand } from '@aws-sdk/client-sqs';

const SQS_QUEUE_URL = process.env.SQS_QUEUE_URL;
ok(SQS_QUEUE_URL);

const sqs = new SQSClient();
const num = 10;

(async () => {
    for (const i of Array(num).keys()) {
        console.log(`send ${i}`);
        await sqs.send(new SendMessageCommand({
            QueueUrl: SQS_QUEUE_URL,
            MessageBody: `this is ${i}`,
            MessageDeduplicationId: process.hrtime.bigint().toString(),
            MessageGroupId: "group1",
            // MessageGroupId: process.hrtime.bigint().toString(),
        }));
    }

    await Promise.all(Array.from(Array(num).keys()).map(async () => {
        for (;;) {
            const res = await sqs.send(new ReceiveMessageCommand({
                QueueUrl: SQS_QUEUE_URL,
                MaxNumberOfMessages: 3,
                WaitTimeSeconds: 1,
            }));
            if (!res.Messages) {
                return;
            }
            console.log(`received ${res.Messages.length} messages`);
            for (const m of res.Messages) {
                console.log(`body: ${m.Body}`);
                await new Promise(r => setTimeout(r, 1000));
                console.log(`body: ${m.Body} ... done`);
                await sqs.send(new DeleteMessageCommand({
                    QueueUrl: SQS_QUEUE_URL,
                    ReceiptHandle: m.ReceiptHandle,
                }));
            }
        }
    }));
})()
