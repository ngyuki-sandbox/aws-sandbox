
exports.handler = function(event, context) {
    // console.log(JSON.stringify({event, context}, null, 2));
    if (Math.random() > 0.5) {
        throw new Error('oops');
    }
    console.log("Successed");
    return 0;
}
