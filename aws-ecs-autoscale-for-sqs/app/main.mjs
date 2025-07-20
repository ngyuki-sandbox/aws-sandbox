import { SQS } from "@aws-sdk/client-sqs";
import { setTimeout } from "timers/promises";

const SQS_QUEUE_URL = process.env.SQS_QUEUE_URL;

const sqs = new SQS();

let terminated = false;

["SIGINT", "SIGHUP", "SIGTERM"].forEach((signal) => {
    process.on(signal, () => {
        console.log({ signal });
        terminated = true;
    });
});

(async () => {
    console.log(`process started`);
    while (!terminated) {
        console.log(`receiveing`);
        const res = await sqs.receiveMessage({
            QueueUrl: SQS_QUEUE_URL,
            WaitTimeSeconds: 10,
        });
        if (!res.Messages) {
            console.log(`received empty messages`);
            continue;
        }
        console.log(`received ${res.Messages.length} messages`);
        for (const m of res.Messages) {
            console.log(m.Body);
            await setTimeout(1000);
            if (m.ReceiptHandle) {
                await sqs.deleteMessage({
                    QueueUrl: SQS_QUEUE_URL,
                    ReceiptHandle: m.ReceiptHandle,
                });
            }
        }
    }
    console.log(`process finished`);
})();
