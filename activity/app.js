const express = require('express');
const app = express();
const port = 3000;

app.get('/activity', (req, res) => {
  res.send('Welcome to the Activity service!');
});

app.listen(port, () => {
  console.log(`Activity service listening on port ${port}`);
});