/**************
*** AWS SDK ***
***************/
var AWS = require('aws-sdk'),
region = process.env.TF_VAR_region,
secretName = process.env.TF_VAR_db_secret,
secret,
decodedBinarySecret;
var client = new AWS.SecretsManager({region: region});

/**************
*** DB seed ***
***************/
client.getSecretValue({ SecretId: secretName }, function (err, data) {
  if (err) console.log(err, err.stack);
  if ("SecretString" in data) {
        secret = data.SecretString;
      } else {
                let buff = new Buffer(data.SecretBinary, "base64");
                decodedBinarySecret = buff.toString("ascii");
                }
    const secretJSON = JSON.parse(secret);
    const mysql_create = require('mysql');
    const con_create = mysql_create.createConnection({
        host: secretJSON.db_dns+".private_host_zone",
        user: secretJSON.username,
        password: secretJSON.password
    });

    con_create.connect(function(err) {
        if (err) throw err;
        con_create.query('CREATE DATABASE IF NOT EXISTS main;');
        con_create.query('USE main;');
        con_create.query('CREATE TABLE IF NOT EXISTS users(id int NOT NULL AUTO_INCREMENT, username varchar(30), email varchar(255), age int, PRIMARY KEY(id));', function(error, result, fields) {
            console.log(result);
        });
        con_create.end();
    });

});

/**************
*** DB mgmt ***
***************/
const mysql = require('mysql');
var con;
client.getSecretValue({ SecretId: secretName }, function (err, data) {
  if (err) console.log(err, err.stack);
  if ("SecretString" in data) {
        secret = data.SecretString;
      } else {
                let buff = new Buffer(data.SecretBinary, "base64");
                decodedBinarySecret = buff.toString("ascii");
                }
  const secretJSON = JSON.parse(secret);
  con = mysql.createConnection({
    host: secretJSON.db_dns+".private_host_zone",
    user: secretJSON.username,
    password: secretJSON.password,
    database: "main"
  });
});

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
app.get('/view', (req, res) => {
    con.connect(function(err) {
        con.query(`SELECT * FROM main.users`, function(err, result, fields) {
            if (err) res.send(err);
            if (result) res.render('viewdb', {obj: result});
        });
    });
});
app.post('/view/add', (req, res) => {
    if (req.body.username && req.body.email && req.body.age) {
        console.log('Request received');
        con.connect(function(err) {
            con.query(`INSERT INTO main.users (username, email, age) VALUES ('${req.body.username}', '${req.body.email}', '${req.body.age}')`, function(err, result, fields) {
                if (err) res.send(err);
                if (result) res.redirect('/view'); //res.send({username: req.body.username, email: req.body.email, age: req.body.age});
                if (fields) console.log(fields);
            });
        });
    } else {
        console.log('Missing a parameter');
    }
});
app.listen(port);
