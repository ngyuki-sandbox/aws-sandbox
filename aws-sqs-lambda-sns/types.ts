export type { PublishBatchRequestEntry } from "@aws-sdk/client-sns";

export interface LambdaSQSInputEvent {
    Records: {
        eventSource: "aws:sqs",
        eventSourceARN: string,
        awsRegion: string,
        messageId: string,
        receiptHandle: string,
        body: string,
        attributes: Record<string, string>,
        messageAttributes?: {
            source?: {
                dataType: string,
                stringValue?: string,
            }
        },
        md5OfBody: string,
    }[],
};
