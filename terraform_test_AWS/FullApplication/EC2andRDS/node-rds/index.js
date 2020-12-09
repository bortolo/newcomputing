const mysql_create = require('mysql');

const con_create = mysql_create.createConnection({
    host: process.env.TF_VAR_db_private_dns+".private_host_zone",
    user: process.env.TF_VAR_db_username,
    password: process.env.TF_VAR_db_password
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

const mysql = require('mysql');

const con = mysql.createConnection({
  host: process.env.TF_VAR_db_private_dns+".private_host_zone",
  user: process.env.TF_VAR_db_username,
  password: process.env.TF_VAR_db_password,
  database: "main"
});

const port = 8080;

var express = require('express');
var bodyParser = require('body-parser'); // Loads the piece of middleware for managing the settings
//var urlencodedParser = bodyParser.urlencoded({ extended: false });

var app = express();

app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies
app.set('views', './views');
app.set('view engine', 'ejs');

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
