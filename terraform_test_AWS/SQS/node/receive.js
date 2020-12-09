// Load the AWS SDK for Node.js
const AWS = require('aws-sdk');

var region = process.env.TF_VAR_region;
var apiVersion = process.env.TF_VAR_apiVersion;

// Set the region 
AWS.config.update({ region: region });

// Create SQS service object
const sqs = new AWS.SQS({ apiVersion: apiVersion });

// Replace with your accountid and the queue name you setup
const queueUrl = process.env.TF_VAR_queueUrl;

// Setup the receiveMessage parameters
const params = {
    QueueUrl: queueUrl,
    MaxNumberOfMessages: 1,
    VisibilityTimeout: 0,
    WaitTimeSeconds: 0
};

sqs.receiveMessage(params, (err, data) => {
    if (err) {
        console.log(err, err.stack);
    } else {
        if (!data.Messages) {
            console.log('Nothing to process');
            return;
        }

        const orderData = JSON.parse(data.Messages[0].Body);
        console.log('Order received', orderData);

        // orderData is now an object that contains order_id and date properties
        // Lookup order data from data storage
        // Execute billing for order
        // Update data storage

        // Now we must delete the message so we don't handle it again
        const deleteParams = {
            QueueUrl: queueUrl,
            ReceiptHandle: data.Messages[0].ReceiptHandle
        };
        sqs.deleteMessage(deleteParams, (err, data) => {
            if (err) {
                console.log(err, err.stack);
            } else {
                console.log('Successfully deleted message from queue');
            }
        });
    }
});