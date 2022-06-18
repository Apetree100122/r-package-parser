# RPackageParser

_Note:_ Please read this [confluence page](https://datacamp.atlassian.net/wiki/spaces/PRODENG/pages/2314469377/RDocumentation) which explains the complete architecture of how RDocumentation works.

R Package that builds on Hadley Wickham's `pkgdown` package, to parse R Documentation to be used on R Documentation. This package is being used in the pipeline of lambda workers.

We have forked our own version of `pkgdown` which we use here: https://github.com/datacamp/pkgdown

## How it works

1. Read messages from [rdocs-r-worker](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F301258414863%2Frdoc-r-worker) SQS queue. This will contain the packages that need to be processed. The message types are documented in the [/docs](/docs) folder.
2. Process the messages into a JSON files that we dump in S3 for logging.
3. If the message is successfully processed, add the JSON to the [rdocs-app-worker](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F301258414863%2Frdoc-app-worker) SQS queue (that will then be handled in the [rdocs app API](https://github.com/datacamp/RDocumentation-app/tree/master/api)).
4. If the processing fails, add an error job to the [rdoc-r-worker-deadletter](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F301258414863%2Frdoc-r-worker-deadletter) queue.

## Local development

## Installing the package

```R
devtools::install_github("datacamp/r-package-parser")
```

### Polling and posting to SQS queues

First, add a file `.env.R` in the package root folder with info that AWS needs:

```R
Sys.setenv(AWS_ACCESS_KEY_ID = "ACCESS_KEY_ID",
           AWS_SECRET_ACCESS_KEY = "SECRET_ACCESS_KEY",
           AWS_DEFAULT_REGION = "us-west-1",
           DEST_QUEUE = "rdoc-app-worker",
           SOURCE_QUEUE = "rdoc-r-worker",
           DEADLETTER_QUEUE = "rdoc-r-worker-deadletter")

```

You need to add AWS keys that have write access to the SQS queues so that you can post messages to the queue.
You can find these variables in the AWS Parameter Store and request access from the DataCamp infra team if you don't have them.

After that, you can run `main()`; this will poll the SQS queues and do all the processing:

```R
RPackageParser::main()
```

### Testing locally without SQS queues

If you just want to test pulling a package and generating the output that will be added to the destination queue, just open this project in RStudio and run these commands in the console:

1. `devtools::load_all(".")`
2. `library("RPackageParser")`
3. `res <- process_package("https://cran.r-project.org/src/contrib/REdaS_0.9.4.tar.gz", "REdaS", "cran")`: replace these arguments with the ones of the package you want to test.
4. `write(jsonlite::toJSON(res$topics[[1]],auto_unbox = TRUE), file = 'topic.json')`: this will create a `topic.json` file in the root of the project that contains the JSON that will be added to the queue. This is what the API will process before adding the topic to the mysql database.
