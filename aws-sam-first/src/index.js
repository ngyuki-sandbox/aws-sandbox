exports.handler = (event) => {
    console.log('hello sam!!!');
    console.log(JSON.stringify({event}, null, 2));
    return {
        statusCode: 200,
        body: JSON.stringify({event}, null, 2),
    };
}
