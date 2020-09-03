import AWS from 'aws-sdk'

const sqs = new AWS.SQS();
const queueUrl = process.env.SQS_QUEUE_URL || '';

export async function handler(input: { para?: string }) {
    const para = parseInt(input.para || "1");
    const start = new Date().getTime();

    let num = 0;
    let timeover = false;
    const timer = setTimeout(()=> { timeover = true }, 10000);

    try {
        const promises = Array.from(Array(para)).map(async () => {
            while (!timeover) {
                const data = await sqs.receiveMessage({
                    QueueUrl: queueUrl,
                    MaxNumberOfMessages: 10,
                    WaitTimeSeconds: 0,
                }).promise();

                const messages = data.Messages || [];
                if (messages.length === 0) {
                    break;
                }

                num += messages.length;

                const entries = [];
                for (const m of messages) {
                    if (m.ReceiptHandle) {
                        entries.push({
                            Id: entries.length.toString(),
                            ReceiptHandle: m.ReceiptHandle,
                        });
                    }
                }
                await sqs.deleteMessageBatch({
                    QueueUrl: queueUrl,
                    Entries: entries,
                }).promise();
            };
        });

        await Promise.all(promises);

        const miliseconds = new Date().getTime() - start;
        console.log(`${para} para, ${num} messages, ${miliseconds} ms`);
    } finally {
        clearTimeout(timer);
    }
}
