
export const handler = async (event) => {
    const headers = event.headers || {};
    const data = event.headers['x-amzn-oidc-data'];
    const body = {
        headers,
        data: decodeOidcData(data),
    };
    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json; charset=utf-8',
        },
        body: JSON.stringify(body, null, 2),
    };
};

function decodeOidcData(data) {
    try {
        if (!data) {
            return { err: 'Missing x-amzn-oidc-data' };
        }
        const parts = data.split('.');
        if (parts.length !== 3) {
            return { err: 'Invalid JWT format in x-amzn-oidc-data' };
        }
        return {
            header: JSON.parse(decodeBase64url(parts[0])),
            payload: JSON.parse(decodeBase64url(parts[1])),
            signature: parts[2],
        };
    } catch (err) {
        return { err: `Failed to decode x-amzn-oidc-data: ${String(err)}` };
    }
}

function decodeBase64url(data) {
    const base64 = data.replace(/-/g, '+').replace(/_/g, '/');
    return Buffer.from(base64, 'base64').toString('utf-8');
}
