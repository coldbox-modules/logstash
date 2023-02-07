/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 */
component {

    // Module Properties
    this.title 				= "logstash";
    this.author 			= "Ortus Solutions";
    this.webURL 			= "https://github.com/coldbox-modules/logstash";
    this.description 		= "A logstash module for the Coldbox Platform";

    // Model Namespace
	this.modelNamespace		= "logstash";

	this.entrypoint         = "logstash";

    // CF Mapping
    this.cfmapping			= "logstash";

    // Dependencies
    this.dependencies 		= [ "cbelasticsearch" ];

    /**
     * Configure Module
     */
    function configure(){
		var applicationName = server.coldfusion.productname == "Lucee" ? getApplicationSettings().name : getApplicationMetadata().name;

        settings = {
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
			"dataStreamPattern" 	: getSystemSetting( "LOGSTASH_DATASTREAMPATTERN", "logs-coldbox-*" ),
			// The name of the ILM policy for log rotation
			"ILMPolicyName"   		: getSystemSetting( "LOGSTASH_ILMPOLICY", "cbelasticsearch-logs" ),
			// The name of the component template to apply
			"componentTemplateName" : getSystemSetting( "LOGSTASH_COMPONENT_TEMPLATE", "cbelasticsearch-logs-mappings" ),
			// The name of the index template to apply
			"indexTemplateName" 	: getSystemSetting( "LOGSTASH_INDEX_TEMPLATE", "cbelasticsearch-logs" ),
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
        };

        // Try to look up the release based on a box.json
        if( !isNull( appmapping ) ) {
            var boxJSONPath = expandPath( '/' & appmapping & '/box.json' );
            if( fileExists( boxJSONPath ) ) {
                var boxJSONRaw = fileRead( boxJSONPath );
                if( isJSON( boxJSONRaw ) ) {
                    var boxJSON = deserializeJSON( boxJSONRaw );
                    if( boxJSON.keyExists( 'version' ) ) {
                        settings.release = boxJSON.version;
                        if( boxJSON.keyExists( 'slug' ) ) {
                            settings.release = boxJSON.slug & '@' & settings.release;
                        } else if( boxJSON.keyExists( 'name' ) ) {
                            settings.release = boxJSON.name & '@' & settings.release;
                        }
                    }
                }
            }
        }

        interceptors = [
            //API Security Interceptor
            { class="logstash.interceptors.APISecurity" }
		];

		if( settings.enableAPI ){
			routes = [
				// Module Entry Point
				{
					pattern = "/api/logs",
					handler = "API",
					action = {
						"HEAD"		: "onInvalidHTTPMethod",
						"OPTIONS"	: "onInvalidHTTPMethod",
						"GET"   	: "onInvalidHTTPMethod",
						"POST"  	: "create",
						"DELETE"	: "onInvalidHTTPMethod",
						"PUT"   	: "create",
						"PATCH" 	: "onInvalidHTTPMethod"
					}
				}
			];
		}

    }

    /**
     * Fired when the module is registered and activated.
     */
    function onLoad(){
		loadAppenders();
	}

    /**
     * Fired when the module is unregistered and unloaded
     */
	function onUnload(){}

	function afterConfigurationLoad(){}
    /**
     * Load LogBox Appenders
     */
    private function loadAppenders(){

		var appenderProperties = duplicate( settings );

		if( len( appenderProperties.indexPrefix ) ){
			appenderProperties.index = settings.indexPrefix;
		}


        if( settings.enableAppenders ){
			logBox.registerAppender(
				name 		= 'logstash_appender',
				class 		= settings.transmission == "direct" ? "cbelasticsearch.models.logging.LogstashAppender" : "logstash.models.logging.APIAppender",
				properties  = appenderProperties,
				levelMin 	= logBox.logLevels[ settings.levelMin ],
				levelMax 	= logBox.logLevels[ settings.levelMax ]
			);

			var appenders = logBox.getAppendersMap( 'logstash_appender' );
			// Register the appender with the root loggger, and turn the logger on.
			var root = logBox.getRootLogger();
			root.addAppender( appenders[ 'logstash_appender' ] );

		}

		// If the api
		if( settings.enableAPI ){
			binder.map( "EventAppender@logstash" )
                        .to( '#this.cfmapping#.models.logging.APIEventAppender' )
						.initWith(
							name="logstash_api_event_appender",
							properties=appenderProperties
						)
						.asSingleton();
		}
    }

}
