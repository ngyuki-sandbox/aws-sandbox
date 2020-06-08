
module.exports.hello = async event => {
    console.log(JSON.stringify({ event }, null, 2));
    return {
        statusCode: 200,
        body: JSON.stringify({ event }, null, 2),
    };
};

module.exports.success = async event => {
    console.log(JSON.stringify({ event }, null, 2));
    return {
        statusCode: 200,
        body: JSON.stringify({ event }, null, 2),
    };
};
