import assert from "node:assert";
import { CodeBuildClient, StartBuildCommand } from "@aws-sdk/client-codebuild";

const CODEBUILD_PROJECT = process.env.CODEBUILD_PROJECT;
const GITLAB_URL = process.env.GITLAB_URL;
const GITLAB_TOKEN = process.env.GITLAB_TOKEN;
const SECRET_TOKEN = process.env.SECRET_TOKEN;
const RUNNER_TAGS = JSON.parse(process.env.RUNNER_TAGS);

assert.ok(CODEBUILD_PROJECT);
assert.ok(GITLAB_URL);
assert.ok(GITLAB_TOKEN);
assert.ok(SECRET_TOKEN);
assert.ok(Array.isArray(RUNNER_TAGS));

const client = new CodeBuildClient();

export async function handler(event) {
    await perform(event);
    return {
        statusCode: 200,
        body: JSON.stringify({ message: 'ok' }),
    };
}

async function perform(event) {
    const body = JSON.parse(event.body);
    console.log(JSON.stringify({ ...event, body }, null, 2));

    if (body.build_status !== "pending") {
        console.log(`skipped ... build_status:${body.build_status}`);
        return false;
    }

    console.log(`ready ... build_status:${body.build_status}`);

    assert.ok(event.headers["x-secret-token"] === SECRET_TOKEN, "invalid secret-token");

    const url = `${GITLAB_URL}/api/v4/projects/${body.project_id}/jobs/${body.build_id}`;
    const res = await fetch(url, { headers: { "PRIVATE-TOKEN": GITLAB_TOKEN }});
    const data = await res.json();
    const tags = data.tag_list;

    if (!(Array.isArray(tags) && tags.every(v => RUNNER_TAGS.includes(v)))) {
        console.log(`skipped ... tags requires:${JSON.stringify(data.tag_list)} supports:${JSON.stringify(RUNNER_TAGS)}`);
        return false;
    }

    const response = await client.send(new StartBuildCommand({
        projectName: CODEBUILD_PROJECT,
    }));

    console.log(JSON.stringify({
        projectName: CODEBUILD_PROJECT,
        response,
    }, null, 2));

    return true;
}
