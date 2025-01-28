resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "bedrock-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        "height" : 10,
        "width" : 24,
        "y" : 0,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [{ "expression" : "SEARCH('{AWS/Bedrock,ModelId} MetricName=\"Invocations\"', 'SampleCount', 60)", "label" : "$${PROP('Dim.ModelId')}", "period" : 60 }]
          ],
          "title" : "Invocation Count",
          "view" : "timeSeries",
          "timezone" : "LOCAL",
          "stacked" : true,
          "region" : "us-east-1",
          "stat" : "SampleCount"
        }
      }
    ]
  })
}
