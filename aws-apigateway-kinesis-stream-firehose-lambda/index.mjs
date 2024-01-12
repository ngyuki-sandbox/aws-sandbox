
function parse(data) {
    try {
        const json = Buffer.from(data, 'base64').toString();
        return JSON.parse(json);
    } catch (err) {
        return { unparsed: data };
    }
}

export const handler = async (event) => {
    event.Records.forEach((record) => {
        console.log({
            partitionKey: record.kinesis.partitionKey,
            data: parse(record.kinesis.data),
        });
    });
    return {};
};
