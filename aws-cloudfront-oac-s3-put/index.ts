import { ok } from "node:assert";
import * as fs from "node:fs";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { Upload } from "@aws-sdk/lib-storage";

const s3Client = new S3Client({
    bucketEndpoint: true,
    credentials: { accessKeyId: "dummy", secretAccessKey: "dummy" },
});

async function main() {
    const CLOUDFRONT_URL = process.env.CLOUDFRONT_URL;
    ok(CLOUDFRONT_URL);

    const res = await s3Client.send(new PutObjectCommand({
        Bucket: CLOUDFRONT_URL,
        Key: "test.txt",
        ContentType: "text/plain",
        Body: "this is test",
    }));
    console.log(res);

    const stream = fs.createReadStream("sample.png");
    const upload = new Upload({
        client: s3Client,
        params: {
            Bucket: CLOUDFRONT_URL,
            Key: "sample.png",
            ContentType: "image/png",
            Body: stream,
        },
    });
    const done = await upload.done();
    console.log(done);
}

main();
