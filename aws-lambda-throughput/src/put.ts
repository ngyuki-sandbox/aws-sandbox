import AWS from 'aws-sdk'

const sqs = new AWS.SQS();
const queueUrl = process.env.SQS_QUEUE_URL || '';

(async () => {
    const promises = Array.from(Array(10)).map(async () => {
        for (let i=0; i<100; i++) {
            await sqs.sendMessageBatch({
                QueueUrl: queueUrl,
                Entries: Array.from(Array(10).keys()).map(i => {
                    return {
                        Id: i.toString(),
                        MessageBody: 'x',
                    }
                })
            }).promise();
        }
    });

    await Promise.all(promises);
})();
