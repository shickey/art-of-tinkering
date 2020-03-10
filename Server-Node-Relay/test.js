const axios = require('axios');
const fs = require('fs');

fs.readFile('test.sprite3', (err, data) => {
    if (err) { return console.log(err) }
    axios.post('http://localhost:8080',
        String.fromCharCode.apply(null, new Uint16Array(data)))
    .then(res => {
        console.log(res.data);
    })
    .catch(err => {
        console.log(err);
    });
});
