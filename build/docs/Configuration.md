# Configuration

## ColdBox Installation

Since this module utilizes other module dependencies, which are designed to work within the Coldbox framework, it may only be used within the context of a Coldbox application.  

By just installing the module a  LogBox Logstash appender will be registered to capture all messages of FATAL or ERROR severity and will ship those logs to an [Elasticsearch time-series DataStream](https://cbelasticsearch.ortusbooks.com/v/v3.x-6/indices/data-streams)

## Configuration

The `cbElasticsearch` module is bundled in the installation of this module so, if you are utilizing a [direct connection](#transmission-modes), you will need to first configure the Elasticsearch connection in `config/Coldbox.cfc`.  See [cbElasticsearch configuration](https://cbelasticsearch.ortusbooks.com/v/v3.x-6/getting-started/configuration).

The default configuration structure for the module looks like this.  Note that environment variables or java properties may be provided to configure the module with adding any additional code to your `config/Coldbox.cfc` file:

```js
moduleSettings = {
	"logstash" : {
		// The name of this application, which will allow for grouping of logs
		"applicationName" 		: getSystemSetting( "LOGSTASH_APPLICATION_NAME", server.coldfusion.productname eq "Lucee" ? getApplicationSettings().name : getApplicationMetadata().name ),
		// Whether to enable the API endpoints to receive log messages
		"enableAPI" 			: getSystemSetting( "LOGSTASH_ENABLE_API", true ),
		// Whether to automatically enabled log appenders
		"enableAppenders" 		: getSystemSetting( "LOGSTASH_ENABLE_APPENDERS", true ),
		// The type of transmission mode for this module - `direct` or `api`
		"transmission" 			: getSystemSetting( "LOGSTASH_TRANSMISSION_METHOD", "direct" ),
		// only used if the transmission setting is `api`
		"apiUrl" 				: getSystemSetting( "LOGSTASH_API_URL", "" ),
		// Regex used to whitelist remote addresses allowed to transmit to the API - by default only 127.0.0.1 is allowed to transmit messages to the API
		"apiWhitelist" 			: getSystemSetting( "LOGSTASH_API_WHITELIST", "127.0.0.1" ),
		// a user-provided API token - which must match the token configured on the remote API microservice leave empty if using IP whitelisting
		"apiAuthToken" 			: getSystemSetting( "LOGSTASH_API_TOKEN", "" ),
		// Min/Max levels for the appender
		"levelMin" 				: getSystemSetting( "LOGSTASH_LEVEL_MIN", "FATAL" ),
		"levelMax" 				: getSystemSetting( "LOGSTASH_LEVEL_MAX", "ERROR" ),
		// A closure, which may be used in the configuration to provide custom information. Will be stored in the `userinfo` key in your logstash logs
		"userInfoUDF"       	: function(){ return {}; },
		// The name of the data stream to use for the appender
		"dataStream"    		: getSystemSetting( "LOGSTASH_DATASTREAM", "logs-coldbox-logstash-appender" ),
		// The data stream pattern to use for index templates
		"dataStreamPattern" 	: getSystemSetting( "LOGSTASH_DATASTREAM_PATTERN", "logs-coldbox-*" ),
		// The name of the ILM policy for log rotation
		"ILMPolicyName"   		: getSystemSetting( "LOGSTASH_ILMPOLICY", "cbelasticsearch-logs" ),
		// Option full JSON representation of an ILM lifecycle policy
		"lifecyclePolicy"       : javacast( "null", 0 ),
		// The name of the component template to apply
		"componentTemplateName" : getSystemSetting( "LOGSTASH_COMPONENT_TEMPLATE", "cbelasticsearch-logs-mappings" ),
		// The name of the index template to apply
		"indexTemplateName" 	: getSystemSetting( "LOGSTASH_INDEX_TEMPLATE" "cbelasticsearch-logs" ),
		// Retention of logs in number of days
		"retentionDays"   		: getSystemSetting( "LOGSTASH_RETENTION_DAYS", 365 ),
		// The number of shards to use for new logstash indices
		"indexShards"       	: getSystemSetting( "LOGSTASH_INDEX_SHARDS", 1 ),
		// The number of replicas to use for new logstash indexes
		"indexReplicas"     	: getSystemSetting( "LOGSTASH_INDEX_REPLICAS", 0 ),
		// Backward compatiblility keys for migrating old rotational indices
		"indexPrefix"           : getSystemSetting( "LOGSTASH_INDEX_PREFIX", "" ),
		"migrateIndices"  		: getSystemSetting( "LOGSTASH_MIGRATE_V2", false ),
		// Whether to throw an error when a log document fails to save
		"throwOnError"    		: true
	}
}
```

The environment variable names are noted above in the `getSystemSetting` methods.  For clarity, they are:

- `LOGSTASH_APPLICATION_NAME` - The application name to transmit with all log entries
- `LOGSTASH_ENABLE_API` - disable or enable the API endpoint
- `LOGSTASH_ENABLE_APPENDERS` - disable or enable the application appenders ( built-in error logging )
- `LOGSTASH_TRANSMISSION_METHOD` - `direct` or `api`
- `LOGSTASH_API_URL` - The url of your logstash API service
- `LOGSTASH_API_WHITELIST` - Regex for host IP addresses allowed to transmit messages
- `LOGSTASH_API_TOKEN` - A user-provided token for ensuring permissability betwen the client and API server
- `LOGSTASH_LEVEL_MIN` - A minimum log level for the appender - `FATAL` is probably the best choice.
- `LOGSTASH_LEVEL_MAX` - The max level to log.  Defaults to `ERROR`, but could be set lower ( e.g. `WARN` ) if more logging output is desired.
- `LOGSTASH_DATASTREAM` - The name of the time-series Data Stream to use for your logs.  Defaults to `logs-coldbox-logstash-appender`
- `LOGSTASH_DATASTREAM_PATTERN` - The index pattern for the the backing component/index templates to use.  In most cases, you will not need to provide this.
- `LOGSTASH_ILMPOLICY` - The name of the ILM policy to use for your data stream. In most cases, you will not need to provide this.
- `LOGSTASH_COMPONENT_TEMPLATE` - The name of the component template to use for the index template. In most cases, you will not need to provide this.
- `LOGSTASH_INDEX_TEMPLATE` - The name of the index template to apply to your datastream. In most cases, you will not need to provide this.
- `LOGSTASH_RETENTION_DAYS` - The number of days to retain log data.  Defaults to 365 days.
- `LOGSTASH_INDEX_SHARDS` - The number of shards to use for indices created by the data stream. Defaults to 1.
- `LOGSTASH_INDEX_REPLICAS` - The number of replicas to use for indices created by the data stream.  Defaults to 0.
- `LOGSTASH_MIGRATE_V2` - If this variable and the the below variable are provided, the appender registration will attempt to migrate your data from the v2 indices to the new data stream in v3
- `LOGSTASH_INDEX_PREFIX` - Backward compatibility field for v2. If this key is present and the `migrateIndices` 

### Transmission Modes

As noted above, this module may be used with either a direct connection to an elasticsearch server ( configured in your Coldbox application or via environment variables ) or it can transmit to a microservice version of itself via API.   There are two valid transmission modes:  `direct` ( default ) and `api`.  In the case of the former, messages are logged directly to an Elasticsearch server via the `cbElasticsearch` module.  In the case of the latter, you will need to supply configuration options for the API endpoint to be used in logging messages.


#### Direct

For a direct configuration, with no API enabled, our settings would be the following:

```js
moduleSettings = {
	"logstash" : {
		"enableAPI" 		: false
	}
}
```

### API

Because direct is the default the above configuration only disables the API.  No need to pass in additional configuration options.
For an API transmission, our configuration becomes a little more complex:

```js
moduleSettings = {
	"logstash" : {
		"transmission" : "api",
		"apiUrl" : "https://my.logstashmicroservice.com/logstash/api/logs,
		"apiAuthToken : "[My SECRET Token]"
	}
}
```

Note that the token is provided by you. The token on the client must match the token on the receiving microservice, however, so this is an excellent use case for environment variables.

#### Microservice configuration

If you are planning on running a separate instance to receive log messages, you can deploy a Coldbox application, with only the logstash module installed, as a microservice.  In this case, our configuration would need to whitelist the IP of the client or allow all addresses to transmit with an `apiWhitelist` value of '*'.  An example configuration for this microservice might be:

```js
moduleSettings = {
	"logstash" : {
		// Must match the client tokens
		"apiAuthToken" : "[My SECRET Token]",
		// Allow transmission to the API from all hosts
		"apiWhitelist" : "*"
	}
}
```

#### Custom Lifcycle Policy

You may also provide a custom [lifecycle policy](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-lifecycle-management.html) to the module.  This will supercede the default lifecycle of a simple deletion after 365 days.  This must be supplied as a JSON representation of the policy or as a Policy object. If you supply your own policy, the `retentionDays` setting will not be applied, as you will have to supply it yourself.  Example with three phases after the initial "hot" phase:

```js
moduleSettings = {
	"logstash" : {
		"lifecyclePolicy" : {
			"warm": {
				"min_age": "10d",
				"actions" : {
					// consolidate to 5m intervals after 10 days
					"downsample" : "5m"
				}
			},
			"cold" : {
				"min_age" : "30d"
				"actions" : {
					// consolidate to 1h intervals after 30 days
					"downsample" : "1h"
				}
			},
			"delete": {
				// Delete after 60 days
				"min_age": "60d",
				"actions": {
					"delete": {}
				}
			}
		}
	}
}
```

For more information on ILM policies, [see the documentation](https://cbelasticsearch.ortusbooks.com/v/v3.x-6/indices/managing-indices/index-lifecycles).

#### User Info Closure

A custom user information closure may be provided in your module configuration.  This allows you to append additional information about the state of the error and/or your application ( see the log schema section below ).

If a struct or array, is returned, it is serialized as JSON in the `userinfo` key of the log entry. You may return any string, as well.  Let's say we wanted to capture the `URL` scope, the user's id and the server state information with every logged message.  We could provide the UDF like so:

```js
"userInfoUDF" : function(){
	return {
		"scopes" : {
			"server" : SERVER,
			"url"  : URL
		},
		"userId" : structKeyExists( application, "wirebox" ) ? application.wirebox.getInstance( "SecurityService" ).getAuthenticatedUserId() : ""
	};
}
```

Note that the `userInfoUDF` is designed to fail softly - so as to prevent error messages from being generated from error logging.  As such, if the closure fails you will see this message in the `userInfo` key:  `An error occurred when attempting to run the userInfoUDF provided.  The message received was [ message text of error thrown ]`

## Index naming conventions

By default, the indexes created and used by the Logstash module use the following prefix:  `.logstash-[ lower-cased, alphanumeric application name]`.  The `.logstash-` prefix is a convention used by the ELK stack to denote two things: 

1. The index is non-public
2. The index contains logs.

Tools like Kibana will automatically filter logging indices by looking for this name. 

You may change the default prefix used for logging indices with the `indexPrefix` key in the module settings, or by providing a `LOGSTASH_INDEX_PREFIX` environment variable.