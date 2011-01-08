
exports.ALLOWED_TAGS = {
    b: [], 
    i: [], 
    img: ['src'], 
    a: ['href'], 
    center: [],
    font: ['face', 'color', 'size'],
};


var httpInitialStream = '';
while (httpInitialStream.length < 20000) {
    httpInitialStream += '\n';
}
exports.HTTP_INITIAL_STREAM = httpInitialStream;


var port = 8000;
if (process.argv.length > 2 && !isNaN(process.argv[2])) {
    port = Number(process.argv[2]);
}
exports.PORT = port;
