import { SNSClient, PublishBatchCommand } from "@aws-sdk/client-sns";

/**
 * @typedef {import('./types.ts').LambdaSQSInputEvent} LambdaSQSInputEvent
 * @typedef {import('./types.ts').PublishBatchRequestEntry} PublishBatchRequestEntry
 */

const snsClient = new SNSClient({});
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;

/**
 * @param {LambdaSQSInputEvent} event
 */
export async function handler(event) {
    console.log(JSON.stringify({ input: event }));

    const entries = event.Records.map((record, index) => {
        /** @type {PublishBatchRequestEntry} */
        const output = {
            Id: index.toString(),
            Message: record.body,
            MessageAttributes: {
                source: {
                    DataType: "String",
                    StringValue: record.messageAttributes.source.stringValue ?? "unknown",
                },
            },
        };
        console.log(JSON.stringify({ output }));
        return output;
    });

    const command = new PublishBatchCommand({
        TopicArn: SNS_TOPIC_ARN,
        PublishBatchRequestEntries: entries,
    });

    await snsClient.send(command);
}
