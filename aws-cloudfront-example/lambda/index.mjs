import * as crypto from 'crypto';
import * as querystring from 'querystring';

const key_pair_id = process.env.KEY_PAIR_ID;
const priv_key = process.env.PRIVATE_KEY;
const cf_domain = process.env.CF_DOMAIN;

export async function handler(event, context) {
    const date = new Date();
    const expires = date.getTime() + 300;
    const rawPath = event.rawPath.replace(/^\/[^\/]+\//, '');
    const ip = event.headers["x-forwarded-for"];
    const url = `https://${cf_domain}/${rawPath}`;
    const wild = `https://${cf_domain}/*`;
    const links = {
        canned: url + '?' + generateCannedPolicySignedQuery(key_pair_id, priv_key, expires, url),
        custom: url + '?' + generateCustomPolicySignedQuery(key_pair_id, priv_key, expires, wild, ip),
    };
    return {
        statusCode: '200',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ date, links, event, context }),
    }
}

function generateCannedPolicySignedQuery(key_pair_id, priv_key, expires, resource) {
    const policy = JSON.stringify({
        Statement: [
            {
                'Resource': resource,
                'Condition': {
                    'DateLessThan': {
                        'AWS:EpochTime': expires,
                    },
                },
            },
        ],
    });
    const signature = sign(policy, priv_key);
    const qs = querystring.stringify({
        'Expires': expires,
        'Signature': urlSafeBase64(signature),
        'Key-Pair-Id': key_pair_id,
    });
    return qs.toString();
}

function generateCustomPolicySignedQuery(key_pair_id, priv_key, expires, resource, ip) {
    const policy = JSON.stringify({
        Statement: [
            {
                'Resource': resource,
                'Condition': {
                    'DateLessThan': {
                        'AWS:EpochTime': expires,
                    },
                    "IpAddress": {
                        "AWS:SourceIp": `${ip}/32`,
                    }
                },
            },
        ],
    });
    const signature = sign(policy, priv_key);
    const qs = querystring.stringify({
        'Expires': expires,
        'Policy': urlSafeBase64(Buffer.from(policy)),
        'Signature': urlSafeBase64(signature),
        'Key-Pair-Id': key_pair_id,
    });
    return qs.toString();
}

function sign(policy, priv_key) {
    const signer = crypto.createSign('RSA-SHA1');
    signer.update(policy);
    return signer.sign(priv_key);
}

function urlSafeBase64(buf) {
    return buf.toString('base64').replaceAll('+', '-').replaceAll('=', '_').replaceAll('/', '~');
}
