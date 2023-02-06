# Logging Messages

## Appender Configuration

You can configure additional appenders via the `logBox` configuration key in your `config/Coldbox.cfc` file. If you choose not to use the automatically created appenders, this can give you granular control over the log messages and indexes used for different levels.  Let's say we want to disable the creation of automatic appenders, in favor of specific appenders to capture different information.   In this case, let's use two separate indices - one for `ERROR`s and one for `DEBUG`-`WARN` messages - and transmit them to an API microservice running our Logstash module:

```js
logBox = {
	// Define Appenders
	appenders = {
		file={class="coldbox.system.logging.appenders.RollingFileAppender",
			properties = {
				filename = "app", filePath="/#appMapping#/logs"
			}
		},
		errors={
			"class" : "logstash.models.logging.APIAppender",
			"properties" : {
				"apiURL" : getSystemSetting( "LOGSTASH_API_URL" ),
				"apiToken" : getSystemSetting( "LOGSTASH_API_TOKEN" ),
				"dataStream" : "logs-coldbox-errors",
				"levelMin" : "FATAL",
				"levelMax" : "ERROR"
			}
		},
		debug={
			"class" : "logstash.models.logging.APIAppender",
			"properties" : {
				"apiURL" : getSystemSetting( "LOGSTASH_API_URL" ),
				"apiToken" : getSystemSetting( "LOGSTASH_API_TOKEN" ),
				"dataStrea" : "logs-coldbox-debug",
				"levelMin" : "WARN",
				"levelMax" : "DEBUG"
			}
		}
	},
	// Root Logger
	root = { levelmax="DEBUG", appenders="*" }
};
```

## Log Message Schema.

The log schema used by this appender adheres to the [Elastic Common Schema](https://www.elastic.co/guide/en/ecs/current/ecs-reference.html) for event data.
In terms of the fields stored with each log message, a number of fields are automatically appended to each logstash entry.  Depending on the type of log message, some fields may or may not be present in the stored log entry.  The following are the mapped fields in the Elasticsearch Logstash indices:

```js
{
	"type"        : { "type" : "keyword" },
	"application" : { "type" : "keyword" },
	"release"     : { "type" : "keyword" },
	"level"       : { "type" : "keyword" },
	"category"    : { "type" : "keyword" },
	"appendername": { "type" : "keyword" },
	"timestamp"	  : {
		"type"  : "date",
		"format": "date_time_no_millis"
	},
	"@timestamp"	  : {
		"type"  : "date",
		"format": "date_time_no_millis"
	},
	"message"     : {
		"type" : "text",
		"fields": {
			"keyword": {
				"type": "keyword",
				"ignore_above": 256
			}
		}
	},
	"error" : {
		"extrainfo"   : { "type" : "text" },
		"stacktrace"  : { "type" : "text" }
	},
	"host" : {
		"type" : "object",
		"properties" : {
			"name" : { "type" : "keyword" },
			"hostnamename" : { "type" : "keyword" }
		}
	},
	"event" : {
		"type" : "object",
		"properties" : {
			"name"         : { "type" : "keyword" },
			"route"        : { "type" : "keyword" },
			"routed_url"   : { "type" : "keyword" },
			"layout"       : { "type" : "keyword" },
			"module"       : { "type" : "keyword" },
			"view"         : { "type" : "keyword" },
			"environment"  : { "type" : "keyword" }
		}
	},
	"userinfo" : { "type" : "text" },
	"frames"  : { "type" : "text" }
}
```

Fields typed `keyword` are not searchable, but are exact match fields.  This allows for precise filtering of log messages by, for example, application or level.   Fields typed as `text` are searchable fields in elasticsearch and results matched are scored according to relevancy.  Note that stack traces of error messages are split by line and stored as an array of strings.  The `snapshot` and `event` field objects are only populated with log entries of ERROR or higher.   See above for information on providing data to the `userinfo` field, which is stored as JSON.  This field is stored as text to allow flexibility in storing different types of log message with different types of user info in the index. 

_Note: There are two timestamp fields which contain the same data:  `timestamp` and `@timestamp`.  The latter is simply provided for easy automation with the default configuration for Logstash logs in Kibana.  [Read more on the ELK stack here](https://www.elastic.co/what-is/elk-stack)._

## API Usage

You may transmit any data directly to the logstash API, as long as it follows the mapped schema above.  You may even specify a name of the index prefix to be used in the transmission ( the actual index name will have the rotational appender timestamps applied, according to your configured rotation frequency).  This provides you flexibility in storing additional log files, which may or may not be from your CFML application. 

Within your application, the easiest method for transmission is using the API Appender, which will ensure consistent formatting.  Below is an example of a direct transmission schema. The enpoint is configured to accept PUT or POST requests.

*Endpoint Example*
`( PUT/POST) http://my.logstash.microservice/logstash/api/logs`

*Authorization Header ( if configured in your application )*
`Authorization:Bearer [my api token]`

*Payload*
```js
{
	"type"        : "custom",
	"index"       : "logstash-my-custom-logs"
	"application" : "myapp",
	"release"     : "1.0.0",
	"level"       : "INFO",
	"category"    : "server",
	"appendername": "none",
	"message"     : "My custom log message",
	"extrainfo"   : "My extra info",
	"userinfo"    : "My custom user info"
}
```


Logstash provides you with a single source for all logging information. It is especially effective when running your application within distributed or containerized environments, where log messages and/or errors may be generated from multiple servers and sources.
