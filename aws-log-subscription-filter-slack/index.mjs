import https from 'https'
import zlib from 'zlib'

const url = process.env.SLACK_INCOMING_WEBHOOK_URL;

export async function handler(input) {
    const data = await extract(input.awslogs.data);
    if (data.messageType === 'CONTROL_MESSAGE') {
        return;
    }

    console.log(data);
    console.log({ received: data.logEvents.length });

    await post(generatePayload(transform(data)));
}

export async function extract(data) {
    const zippedInput = new Buffer.from(data, 'base64');
    return await new Promise(function(resolve, reject){
        zlib.gunzip(zippedInput, (error, buffer) => {
            if (error) {
                reject(error);
                return;
            }
            resolve(JSON.parse(buffer.toString('utf8')));
        });
    });
};

export function transform(data) {
    const logGroup = data.logGroup;
    const logStream = data.logStream;
    const subscriptionFilters = data.subscriptionFilters;

    const map = new Map();

    data.logEvents
        .map(log => {
            try {
                return JSON.parse(log.message).message;
            } catch (err) {
                return log.message;
            }
        })
        .forEach(message => {
            map.set(message, (map.get(message) || 0) + 1);
        });

    const length = Math.max(...Array.from(map.values())).toString().length;
    const messages = Array.from(map.entries())
        .map(([message,cnt]) => `${cnt.toString().padStart(length)}: ${message}`)
        .sort().reverse();

    return {logGroup, logStream, subscriptionFilters, messages};
};

export function generatePayload({logGroup, logStream, subscriptionFilters, messages}) {
    return {
        "attachments": [
            {
                "color": "#cccccc",
                "blocks": [
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": `*${logGroup} | ${logStream} | ${subscriptionFilters.join('.')}*`,
                            "verbatim": false
                        }
                    },
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": `\`\`\`\n${messages.join("\n")}\n\`\`\``,
                            "verbatim": false
                        }
                    }
                ]
            }
        ]
    };
}

export async function post(payload) {
    const json = JSON.stringify(payload);
    await new Promise((resolve, reject) => {
        const options = {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
        };
        const request = https.request(url, options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                const response = {
                    status: res.statusCode,
                    headers: res.headers,
                    body: body,
                };
                console.log({response});
                resolve(response);
            });
        });
        request.on('error', (err) => reject(err));
        request.write(json);
        request.end();
    });
}
