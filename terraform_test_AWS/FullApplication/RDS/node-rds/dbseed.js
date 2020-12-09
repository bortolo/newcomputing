const mysql = require('mysql');

// [LOOK HERE] - Update the code with your data before to run it
const con = mysql.createConnection({
  host: "<your-rds-endpoint>",    // Pick up this value from AWS console or look at the output of terraform apply
  user: "<admin-user-for-db>",    // This must be the same value as the one you set up in your .tfvars file
  password: "<password-for-db>",  // This must be the same value as the one you set up in your .tfvars file
});

con.connect(function(err) {
    if (err) throw err;

    con.query('CREATE DATABASE IF NOT EXISTS main;');
    con.query('USE main;');
    con.query('CREATE TABLE IF NOT EXISTS users(id int NOT NULL AUTO_INCREMENT, username varchar(30), email varchar(255), age int, PRIMARY KEY(id));', function(error, result, fields) {
        console.log(result);
    });
    con.end();
});
