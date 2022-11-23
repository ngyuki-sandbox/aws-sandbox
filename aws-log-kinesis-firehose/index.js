exports.handler = async (event) => {
    console.log(event);
    return {
        records: event.records.map(r => ({
            recordId: r.recordId,
            result: "Ok",
            data: r.data,
        })),
    };
};
