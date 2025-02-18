
export async function handler(event) {
    return {
        statusCode: 200,
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ event }, null, 2),
    };
};
