// This lambda function should be triggered by an S3 object upload event.
// It sends the event message to the SQSe and launchs the ECS task. 
var aws = require('aws-sdk');
var sqs = new aws.SQS({apiVersion: '2012-11-05'});
var ecs = new aws.ECS({apiVersion: '2014-11-13'});

// terraform apply will replace these values 
var ecsTaskDefinition = process.env.TD; //"${meetup_task_definition}";
var ecsCluster = process.env.CLUSTER; //"${meetup_cluster}";
var sqsQueue = process.env.QU; //"${meetup_queue}";

exports.handler = function(event, context, callback) {
  var params = {
    MessageBody: JSON.stringify(event),
    QueueUrl: sqsQueue
  };
  sqs.sendMessage(params, function (err, data) {
    if (err) {
      console.error('Error while sending message: ' + err);
    } else {
      console.info('Message sent, ID: ' + data.MessageId);
      var params = {
        taskDefinition: ecsTaskDefinition,
        count: 1,
        cluster: ecsCluster
      };
      ecs.runTask(params, function (err, data) {
        if (err) {
          console.error('Error while starting task: ' + err);
        } else {
          console.info(JSON.stringify(data));
        }
      });
    }
  });
};