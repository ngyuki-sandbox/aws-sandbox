
export const handler = async (event) => {
    try {
        const headers = event.headers ?? {};
        const body = {
            headers,
            data: decodeAuthorization(headers["authorization"]),
        };
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json; charset=utf-8',
            },
            body: JSON.stringify(body, null, 2),
        };
    } catch (err) {
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json; charset=utf-8',
            },
            body: JSON.stringify({ error: String(err) }, null, 2),
        };
    }
};

function decodeAuthorization(auth) {
    const value = auth.split(/ +/)[1];
    const base64Url = value.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const data = Buffer.from(base64, 'base64').toString('utf-8');
    return JSON.parse(data);
}
