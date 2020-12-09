var createError = require('http-errors');
var express = require('express');
var path = require('path');

const { networkInterfaces } = require('os');
var os = require('os');
var osu = require('node-os-utils')
var cpu = osu.cpu

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

app.use(express.static(path.join(__dirname, 'public')));

/* ADD THE APP.JS CODE HERE */

// Add memcache and connect to it
var memjs = require('memjs')
var mc = memjs.Client.create(process.env.MEMCACHIER_SERVERS, {
    failover: true, // default: false
    timeout: 1, // default: 0.5 (seconds)
    keepAlive: true // default: false
})

// Function to validate input
var validate = function(req, res, next) {
    if (req.query.n) {
        number = parseInt(req.query.n, 10);
        if (isNaN(number) || number < 1 || number > 10000000000) {
            res.render('index', { error: 'Please submit a valid number between 1 and 10000000000.' });
            return;
        }
        req.query.n = number;
    }
    next();
}

// Super simple algorithm to find largest prime <= n
var calculatePrime = function(n) {
    var prime = 1;
    for (var i = n; i > 1; i--) {
        var is_prime = true;
        for (var j = 2; j < i; j++) {
            if (i % j == 0) {
                is_prime = false;
                break;
            }
        }
        if (is_prime) {
            prime = i;
            break;
        }
    }
    return prime;
}

// Set up the GET route
// app.get('/', validate, function (req, res) {
//   if(req.query.n) {
//     // Calculate prime and render view
//     var prime = calculatePrime(req.query.n);
//     res.render('index', { n: req.query.n, prime: prime});
//   }
//   else {
//     // Render view without prime
//     res.render('index', {});
//   }
// });

app.get('/', validate, function(req, res) {
    if (req.query.n) {
        var prime;
        var prime_key = 'prime.' + req.query.n;
        // Look in cache
        mc.get(prime_key, function(err, val) {
            if (err == null && val != null) {
                // Found it!
                prime = parseInt(val)
            } else {
                // Prime not in cache (calculate and store)
                prime = calculatePrime(req.query.n)
                mc.set(prime_key, '' + prime, { expires: 0 }, function(err, val) { /* handle error */ })
            }
            // Render view with prime
            res.render('index', { n: req.query.n, prime: prime });
        })
    } else {
        // Render view without prime
        res.render('index', {});
    }
});
app.get('/ip', (req, res) => {
    const nets = networkInterfaces();
    const results = Object.create(null); // or just '{}', an empty object
    var stats = [];
    for (const name of Object.keys(nets)) {
        for (const net of nets[name]) {
            if (net.family === 'IPv4' && !net.internal) {
                stats.push({ cpu_idle: (os.cpus()[0].times.idle / (os.cpus()[0].times.idle + os.cpus()[0].times.sys + os.cpus()[0].times.user + os.cpus()[0].times.nice)).toFixed(2), fremem: (os.freemem() / os.totalmem()).toFixed(2), ip: net.address });
            }
        }
    }
    res.send(stats[0]);
});

/* END DIY CODE */

// catch 404 and forward to error handler
app.use(function(req, res, next) {
    next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
    // set locals, only providing error in development
    res.locals.message = err.message;
    res.locals.error = req.app.get('env') === 'development' ? err : {};

    // render the error page
    res.status(err.status || 500);
    res.render('error');
});

module.exports = app;