const express = require('express');
var bodyParser = require('body-parser');

const app = express();

const AWS = require('aws-sdk');

const sns = new AWS.SNS({ region: 'eu-central-1' });

const port = 3000;

// view engine setup
app.set('views', './views');
app.set('view engine', 'ejs');
app.use(express.static(__dirname + '/public'));

app.use(express.json());
app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true }));
app.get('/status', (req, res) => res.json({ status: "ok", sns: sns }));

app.listen(port, () => console.log(`SNS App listening on port ${port}!`));

app.get('/', function(req, res) {
    res.render('home', {});
});
app.post('/subscribe', (req, res) => {

    console.log(req.body.email)
    let params = {
        Protocol: 'EMAIL',
        TopicArn: 'arn:aws:sns:eu-central-1:152371567679:my-first-topic',
        Endpoint: req.body.email
    };

    sns.subscribe(params, (err, data) => {
        if (err) {
            console.log(err);
        } else {
            console.log(data);
            res.render('home', { email: req.body.email });
        }
    });
});

app.post('/send', (req, res) => {
    let now = new Date().toString();
    let email = `${req.body.message} \n \n This was sent: ${now}`;
    let params = {
        Message: email,
        Subject: req.body.subject,
        TopicArn: 'arn:aws:sns:eu-central-1:152371567679:my-first-topic'
    };

    sns.publish(params, function(err, data) {
        if (err) console.log(err, err.stack);
        else {
            console.log(data);
            res.render('home', { sent: true });
        }
    });
});