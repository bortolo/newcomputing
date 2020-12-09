const mysql = require('mysql');

// [LOOK HERE] - Update the code with your data before to run it
const con = mysql.createConnection({
  host: "<your-rds-endpoint>",    // Pick up this value from AWS console or look at the output of terraform apply
  user: "<admin-user-for-db>",    // This must be the same value as the one you set up in your .tfvars file
  password: "<password-for-db>",  // This must be the same value as the one you set up in your .tfvars file
  database: "main"
});

const port = 3000;

var express = require('express');
var bodyParser = require('body-parser');

var app = express();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
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
                if (result) res.redirect('/view');
                if (fields) console.log(fields);
            });
        });
    } else {
        console.log('Missing a parameter');
    }
});

app.listen(port);
