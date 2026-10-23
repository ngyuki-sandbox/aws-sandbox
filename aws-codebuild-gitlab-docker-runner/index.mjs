import assert from "node:assert";
import crypto from "node:crypto";
import { CodeBuildClient, StartBuildCommand } from "@aws-sdk/client-codebuild";
import { GetParameterCommand, SSMClient } from "@aws-sdk/client-ssm";

const CODEBUILD_PROJECT = process.env.CODEBUILD_PROJECT;
const GITLAB_URL = process.env.GITLAB_URL;
const GITLAB_TOKEN_SSM = process.env.GITLAB_TOKEN_SSM;
const SIGNING_TOKEN_SSM = process.env.SIGNING_TOKEN_SSM;
const RUNNER_DOCKER_TAGS = JSON.parse(process.env.RUNNER_DOCKER_TAGS);
const RUNNER_SHELL_TAGS = JSON.parse(process.env.RUNNER_SHELL_TAGS);

assert.ok(CODEBUILD_PROJECT);
assert.ok(GITLAB_URL);
assert.ok(GITLAB_TOKEN_SSM);
assert.ok(SIGNING_TOKEN_SSM);
assert.ok(Array.isArray(RUNNER_DOCKER_TAGS));
assert.ok(Array.isArray(RUNNER_SHELL_TAGS));

const ssm = new SSMClient();
const codebuild = new CodeBuildClient();

const GITLAB_TOKEN = (await ssm.send(new GetParameterCommand({ Name: process.env.GITLAB_TOKEN_SSM, WithDecryption: true }))).Parameter.Value;
const SIGNING_TOKEN = (await ssm.send(new GetParameterCommand({ Name: process.env.SIGNING_TOKEN_SSM, WithDecryption: true }))).Parameter.Value;

assert.ok(SIGNING_TOKEN.startsWith("whsec_"), "SIGNING_TOKEN must start with 'whsec_'");
const SIGNING_KEY_BUFFER = Buffer.from(SIGNING_TOKEN.slice("whsec_".length), "base64");

const RUNNER_TAGS_BY_EXECUTOR = {
    docker: RUNNER_DOCKER_TAGS,
    shell: RUNNER_SHELL_TAGS,
};

function lookupHeader(headers, name) {
    if (!headers) {
        return undefined;
    }
    const target = name.toLowerCase();
    for (const [key, value] of Object.entries(headers)) {
        if (key.toLowerCase() === target) {
            return value;
        }
    }
    return undefined;
}

function verifyWebhookSignature(rawBody, headers) {
    const webhookId = lookupHeader(headers, "webhook-id");
    const webhookTimestamp = lookupHeader(headers, "webhook-timestamp");
    const webhookSignature = lookupHeader(headers, "webhook-signature");

    if (!webhookId || !webhookTimestamp || !webhookSignature) {
        const obj = {
            hasId: Boolean(webhookId),
            hasTimestamp: Boolean(webhookTimestamp),
            hasSignature: Boolean(webhookSignature),
        };
        console.log(`missing webhook signature headers: ${JSON.stringify(obj)}`);
        return false;
    }

    const timestamp = Number.parseInt(webhookTimestamp, 10);
    if (Number.isNaN(timestamp)) {
        console.log(`invalid webhook timestamp: ${webhookTimestamp}`);
        return false;
    }

    const now = Math.floor(Date.now() / 1000);
    if (Math.abs(now - timestamp) > 300) {
        console.log(`webhook timestamp out of tolerance: ${timestamp} (now: ${now})`);
        return false;
    }

    const signedPayload = `${webhookId}.${webhookTimestamp}.${rawBody}`;
    const expectedSignature = "v1," + crypto
        .createHmac("sha256", SIGNING_KEY_BUFFER)
        .update(signedPayload, "utf-8")
        .digest("base64");

    const expectedBuffer = Buffer.from(expectedSignature, "utf-8");
    const signatures = webhookSignature.split(" ");
    for (const sig of signatures) {
        const sigBuffer = Buffer.from(sig, "utf-8");
        if (expectedBuffer.length === sigBuffer.length && crypto.timingSafeEqual(expectedBuffer, sigBuffer)) {
            return true;
        }
    }

    console.log("webhook signature mismatch");
    return false;
}

export async function handler(event) {
    await perform(event);
    return {
        statusCode: 200,
        body: JSON.stringify({ message: "ok" }),
    };
}

async function perform(event) {
    const rawBody = event.isBase64Encoded ? Buffer.from(event.body, "base64").toString("utf-8") : (event.body ?? "");

    if (!verifyWebhookSignature(rawBody, event.headers)) {
        console.log("invalid webhook signature");
        return false;
    }

    const body = JSON.parse(rawBody);
    console.log(`receive ... ${JSON.stringify({ ...event, body })}`);

    if (body.build_status !== "pending") {
        console.log(`skipped ... build_status:${body.build_status}`);
        return false;
    }

    const url = `${GITLAB_URL}/api/v4/projects/${body.project_id}/jobs/${body.build_id}`;
    const res = await fetch(url, { headers: { "PRIVATE-TOKEN": GITLAB_TOKEN } });
    const data = await res.json();
    console.log(`job details ... ${JSON.stringify(data)}`);

    const tags = data.tag_list;
    if (!Array.isArray(tags) || tags.length === 0) {
        console.log(`skipped ... empty tags`);
        return false;
    }

    const [executor] = Object.entries(RUNNER_TAGS_BY_EXECUTOR)
        .flatMap(([executor, runnerTags]) => tags.every(v => runnerTags.includes(v)) ? [executor] : []);
    if (!executor) {
        console.log(`skipped ... tags requires:${JSON.stringify(tags)} supports docker:${JSON.stringify(RUNNER_DOCKER_TAGS)} shell:${JSON.stringify(RUNNER_SHELL_TAGS)}`);
        return false;
    }
    console.log(`matched executor:${executor}`);

    const response = await codebuild.send(new StartBuildCommand({
        projectName: CODEBUILD_PROJECT,
        environmentVariablesOverride: [
            { name: "EXECUTOR", value: executor, type: "PLAINTEXT" },
        ],
    }));
    console.log(`start build ... ${JSON.stringify({ projectName: CODEBUILD_PROJECT, executor, response })}`);

    return true;
}
