

/**************
*** Routes ****
***************/
const port = 8080;
var express = require('express');
var bodyParser = require('body-parser');

const { networkInterfaces } = require('os');
var os = require('os');

var osu = require('node-os-utils')
var cpu = osu.cpu

var app = express();

app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies
app.set('views', './views');
app.set('view engine', 'ejs');

app.get('/ip', (req, res) => {
  const nets = networkInterfaces();
  const results = Object.create(null); // or just '{}', an empty object
  var ip = [];
  for (const name of Object.keys(nets)) {
      for (const net of nets[name]) {
          if (net.family === 'IPv4' && !net.internal) {
              ip.push({cpu_idle: (os.cpus()[0].times.idle/(os.cpus()[0].times.idle+os.cpus()[0].times.sys+os.cpus()[0].times.user+os.cpus()[0].times.nice)).toFixed(2), fremem: (os.freemem()/os.totalmem()).toFixed(2), ip:net.address});
          }
      }
  }
  res.send(ip[0]);
});
app.get('/', (req, res) => {
      res.render('home');
});
app.listen(port);
