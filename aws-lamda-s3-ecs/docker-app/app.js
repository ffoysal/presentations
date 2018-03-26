let AWS = require('aws-sdk');
let sqs = new AWS.SQS();
let s3 = new AWS.S3();
var fs = require('fs');

let SQS_URL = "";


if (process.env.SQS_URL){
  SQS_URL = process.env.SQS_URL;
}else{
  console.log("SQS_URL NOT FOUND, exiting......")
  process.exit(1);
}

let params = {
  QueueUrl: SQS_URL,
  MaxNumberOfMessages: 1
};

sqs.receiveMessage(params, (err, data) => {
  if (err){
    console.log("Something went wrong", err);
    process.exit(0);
  }
  
  if(!data || !data.Messages){
    console.log("Nothing in the queue");
    process.exit(0);
  }
  let rcvHandle = data.Messages[0].ReceiptHandle;

  let body = JSON.parse(data.Messages[0].Body);
  let bucket = body.Records[0].s3.bucket.name;
  let key = body.Records[0].s3.object.key;

  console.log("Get Bucket Name: "+ bucket + " and file name:"+ key +" From SQS");
  if (bucket && key) {
    let params = {
      Bucket: bucket, 
      Key: key
    };
    s3.getObject(params, function(err, data){
      if (!err) {
        // print file content to the console
        console.log(data.Body.toString());
        // delete the message from the sqs
        let p = {
          QueueUrl: SQS_URL,
          ReceiptHandle: rcvHandle
        }
        sqs.deleteMessage(p, function(er, da) {
          if (er) console.log(er, er.stack); // an error occurred
          else     console.log('\n\nDeleted SQS Message: ', da);// successful response
        });
      }
    });
  }
});