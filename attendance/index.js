const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('Hello from Attendance Service!'));
app.listen(3000, () => console.log('Attendance service running on port 3000'));