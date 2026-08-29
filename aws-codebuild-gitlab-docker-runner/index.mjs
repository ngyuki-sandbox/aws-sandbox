import assert from "node:assert";
import { CodeBuildClient, StartBuildCommand } from "@aws-sdk/client-codebuild";
import { GetParameterCommand, SSMClient } from "@aws-sdk/client-ssm";

const ssm = new SSMClient();
const codebuild = new CodeBuildClient();

const CODEBUILD_PROJECT = process.env.CODEBUILD_PROJECT;
const GITLAB_URL = process.env.GITLAB_URL;
const GITLAB_TOKEN_SSM = process.env.GITLAB_TOKEN_SSM;
const SECRET_TOKEN_SSN = process.env.SECRET_TOKEN_SSN;
const RUNNER_TAGS = JSON.parse(process.env.RUNNER_TAGS);

assert.ok(CODEBUILD_PROJECT);
assert.ok(GITLAB_URL);
assert.ok(GITLAB_TOKEN_SSM);
assert.ok(SECRET_TOKEN_SSN);
assert.ok(Array.isArray(RUNNER_TAGS));

const GITLAB_TOKEN = (await ssm.send(new GetParameterCommand({ Name: process.env.GITLAB_TOKEN_SSM, WithDecryption: true }))).Parameter.Value
const SECRET_TOKEN = (await ssm.send(new GetParameterCommand({ Name: process.env.SECRET_TOKEN_SSN, WithDecryption: true }))).Parameter.Value

export async function handler(event) {
    await perform(event);
    return {
        statusCode: 200,
        body: JSON.stringify({ message: 'ok' }),
    };
}

async function perform(event) {
    const body = JSON.parse(event.body);
    console.log(JSON.stringify({ ...event, body }));

    if (body.build_status !== "pending") {
        console.log(`skipped ... build_status:${body.build_status}`);
        return false;
    }

    console.log(`ready ... build_status:${body.build_status}`);

    if (event.headers["x-gitlab-token"] !== SECRET_TOKEN) {
        console.log(`invalid secret-token`);
        return false;
    }

    const url = `${GITLAB_URL}/api/v4/projects/${body.project_id}/jobs/${body.build_id}`;
    const res = await fetch(url, { headers: { "PRIVATE-TOKEN": GITLAB_TOKEN }});
    const data = await res.json();
    const tags = data.tag_list;

    if (!(Array.isArray(tags) && tags.length > 0 && tags.every(v => RUNNER_TAGS.includes(v)))) {
        console.log(`skipped ... tags requires:${JSON.stringify(data.tag_list)} supports:${JSON.stringify(RUNNER_TAGS)}`);
        return false;
    }

    const response = await codebuild.send(new StartBuildCommand({ projectName: CODEBUILD_PROJECT }));
    console.log(JSON.stringify({ projectName: CODEBUILD_PROJECT, response }));

    return true;
}
