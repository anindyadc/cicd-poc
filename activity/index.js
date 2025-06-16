const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('Hello from Activity Service!'));
app.listen(3000, () => console.log('Activity service running on port 3000'));