const express = require('express');
const app = express();
const port = 3000;

app.get('/attendance', (req, res) => {
  res.send('Welcome to the Attendance service!');
});

app.listen(port, () => {
  console.log(`Attendance service listening on port ${port}`);
});