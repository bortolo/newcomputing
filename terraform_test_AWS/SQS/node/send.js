// Load the AWS SDK for Node.js
const AWS = require('aws-sdk');
var region = process.env.TF_VAR_region;
var apiVersion = process.env.TF_VAR_apiVersion;

// Set the region we will be using
AWS.config.update({ region: region });

// Create SQS service client
const sqs = new AWS.SQS({ apiVersion: apiVersion });

// Replace with your queue Url (get it from terraform output)
const queueUrl = process.env.TF_VAR_queueUrl;

// Setup the sendMessage parameter object
const params = {
    MessageBody: JSON.stringify({
        order_id: 1234,
        date: (new Date()).toISOString()
    }),
    QueueUrl: queueUrl
};

sqs.sendMessage(params, (err, data) => {
    if (err) {
        console.log("Error", err);
    } else {
        console.log("Successfully added message", data.MessageId);
    }
});