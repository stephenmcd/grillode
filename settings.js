
// Mapping of tags and lists of their attributes that are permitted 
// as usernames and messages.
exports.ALLOWED_TAGS = {
    b: [], 
    i: [], 
    img: ['src'], 
    a: ['href'], 
    center: [],
    font: ['face', 'color', 'size'],
};

// Large string of blank data that gets pushed to HTTP clients in 
// order to ensure the browser renders the initial HTML.
var httpInitialStream = '';
while (httpInitialStream.length < 20000) {
    httpInitialStream += '\n';
}
exports.HTTP_INITIAL_STREAM = httpInitialStream;

// Port the server will listen on.
var port = 8000;
if (process.argv.length > 2 && !isNaN(process.argv[2])) {
    port = Number(process.argv[2]);
}
exports.PORT = port;
