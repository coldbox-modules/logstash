[![Build Status](https://travis-ci.org/coldbox-modules/logstash.svg?branch=development)](https://travis-ci.org/coldbox-modules/logstash)

# Welcome to the Logstash Module

This module provides a common interface for sending Logstash logs to elasticsearch.  The module may be used with either a direct connection to an Elasticsearch server or may be installed as a client-ony module, which connects to a separate instance running this module as a microservice.

## LICENSE

Apache License, Version 2.0.

## IMPORTANT LINKS

- Source: https://github.com/coldbox-modules/logstash
- Issues: https://github.com/coldbox-modules/logstash/issues

- [Changelog](changelog.md)

## SYSTEM REQUIREMENTS

- Adobe ColdFusion 2016+
- Lucee 5

## Instructions

Just drop into your modules folder or use the `box` cli to install

```bash
box install logstash
```


## ColdBox Installation

Since this module utilizes other module dependencies, which are designed to work within the Coldbox framework, it may only be used within the context of a Coldbox application.  By just installing the module, the following things will happen automatically for you:

* A Logstash LogBox appender we registered to capture all messages of FATAL or ERROR severity
* An `onException` interceptor will be registered to log all errors that ColdBox sees.

## Configuration

The `cbElasticsearch` module is bundled in the installation of this module so, if you are utilizing a direct connection ( see below ), you will need to first add a configuration to your `config/Coldbox.cfc` for your elasticsearch connection.  Instructions to configure this module may be found [here](https://cbelasticsearch.ortusbooks.com/configuration).

The default configuration structure for the module looks like this.  Note that environment variables or java properties may be provided to configure the module with adding any additional code to your `config/Coldbox.cfc` file:

```js
moduleSettings = {
	"logstash" : {
		// Whether to enable the API endpoints to receive log messages
		"enableAPI" 		: getSystemSetting( "LOGSTASH_ENABLE_API", true ),
		// Whether to automatically enabled log appenders
		"enableAppenders" 	: getSystemSetting( "LOGSTASH_ENABLE_APPENDERS", true ),
		// The type of transmission mode for this module - `direct` or `api`
		"transmission" 		: getSystemSetting( "LOGSTASH_TRANSMISSION_METHOD", "direct" ),
		// only used if the transmission setting is `api`
		"apiUrl" 			: getSystemSetting( "LOGSTASH_API_URL", "" ),
		// Regex used to whitelist remote addresses allowed to transmit to the API - by default only 127.0.0.1 is allowed to transmit messages to the API
		"apiWhitelist" 		: getSystemSetting( "LOGSTASH_API_WHITELIST", "127.0.0.1" ),
		// a user-provided API token - which must match the token configured on the remote API microservice leave empty if using IP whitelisting
		"apiAuthToken" 		: getSystemSetting( "LOGSTASH_API_TOKEN", "" ),
		// Min/Max levels for the appender
		"levelMin" 			: getSystemSetting( "LOGSTASH_LEVEL_MIN", "FATAL" ),
		"levelMax" 			: getSystemSetting( "LOGSTASH_LEVEL_MAX", "ERROR" ),
		// A closure, which may be used in the configuration to provide custom information. Will be stored in the `userinfo` key in your logstash logs
		"userInfoUDF"       : function(){ return {}; },
		// A custom prefix for indices used by the module for logging
		"indexPrefix"       : getSystemSetting( "LOGSTASH_INDEX_PREFIX", ".logstash-" & lcase( REReplaceNoCase(applicationName, "[^0-9A-Z_]", "_", "all") ) ) )
	}
}
```

The environment variable names are noted above in the `getSystemSetting` methods.  For clarity, they are:

- `LOGSTASH_ENABLE_API` - disable or enable the API endpoint
- `LOGSTASH_ENABLE_APPENDERS` - disable or enable the application appenders ( built-in error logging )
- `LOGSTASH_TRANSMISSION_METHOD` - `direct` or `api`
- `LOGSTASH_API_URL` - The url of your logstash API service
- `LOGSTASH_API_WHITELIST` - Regex for host IP addresses allowed to transmit messages
- `LOGSTASH_API_TOKEN` - A user-provided token for ensuring permissability betwen the client and API server
- `LOGSTASH_LEVEL_MIN` - A minimum log level for the appender - `FATAL` is probably the best choice.
- `LOGSTASH_LEVEL_MAX` - The max level to log.  Defaults to `ERROR`, but could be set lower ( e.g. `WARN` ) if more logging output is desired.
- `LOGSTASH_INDEX_PREFIX` - The default prefix used for all logstash indices created by the appender


### Transmission Modes

As noted above, this module may be used with either a direct connection to an elasticsearch server ( configured in your Coldbox application or via the environment ) or it can transmit to a microservice version of itself via API.   There are two valid transmission modes:  `direct` ( default ) and `api`.  In the case of the former, messages are logged directly to an Elasticsearch server via the `cbElasticsearch` module.  In the case of the latter, you will need to supply configuration options for the API endpoint to be used in logging messages.


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

By default, the indexes created and used by the Logstash module use the following prefix:  `.logstash-[ lower-cased, alphanumeric application name]`.  The `.logstash-` prefix is a convention used by the ELK stack to denote two things:  1. The index is non-public 2. The index contains logs.  Tools like Kibana will automatically filter logging indices by looking for this name. 

You may change the default prefix used for logging indices with the `indexPrefix` key in the module settings, or by providing a `LOGSTASH_INDEX_PREFIX` environment variable.

## Appender Configuration

You can configure additional appenders via the `logBox` configuration key in your `config/Coldbox.cfc` file. If you choose not to use the automatically created appenders, this can give you granular control over the log messages and indexes used for different levels.  Let's say we want to disable the creation of automatic appenders, in favor of specific appenders to capture different information.   In this case, let's use two separate indices - one for Errors and one for DEBUG-WARN messages - and transmit them to an API microservice running our Logstash module:

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
				"index" : ".logstash-errors-myapp",
				"levelMin" : "FATAL",
				"levelMax" : "ERROR"
			}
		},
		debug={
			"class" : "logstash.models.logging.APIAppender",
			"properties" : {
				"apiURL" : getSystemSetting( "LOGSTASH_API_URL" ),
				"apiToken" : getSystemSetting( "LOGSTASH_API_TOKEN" ),
				"index" : ".logstash-debugger-myapp",
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
	"message"     : {
		"type" : "text",
		"fields": {
			"keyword": {
				"type": "keyword",
				"ignore_above": 256
			}
		}
	},
	"extrainfo"   : { "type" : "text" },
	"stacktrace"  : { "type" : "text" },
	"snapshot"    : {
		"type" : "object",
		"properties" : {
			"template"       : { "type" : "keyword" },
			"path"           : { "type" : "keyword" },
			"host"           : { "type" : "keyword" },
			"referrer"       : { "type" : "keyword" },
			"browser"        : { "type" : "keyword" },
			"remote_address" : { "type" : "keyword" }
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
	"userinfo" : { "type" : "text" }
}
```

Fields typed `keyword` are not searchable, but are exact match fields.  This allows for precise filtering of log messages by, for example, application or level.   Fields typed as `text` are searchable fields in elasticsearch and results matched are scored according to relevancy.  Note that stack traces of error messages are split by line and stored as an array of strings.  The `snapshot` and `event` field objects are only populated with log entries of ERROR or higher.   See above for information on providing data to the `userinfo` field, which is stored as JSON.  This field is stored as text to allow flexibility in storing different types of log message with different types of user info in the index.

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
	"index"       : ".logstash-my-custom-logs"
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

********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************

#### HONOR GOES TO GOD ABOVE ALL

Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

> "Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the 
Holy Ghost which is given unto us. ." Romans 5:5

### THE DAILY BREAD

 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12