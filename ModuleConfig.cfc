/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 */
component {

    // Module Properties
    this.title 				= "cblogstash";
    this.author 			= "Ortus Solutions";
    this.webURL 			= "https://github.com/coldbox-modules/cblogstash";
    this.description 		= "A logstash module for the Coldbox Platform";

    // Model Namespace
	this.modelNamespace		= "cblogstash";

	this.entrypoint         = "logstash";

    // CF Mapping
    this.cfmapping			= "cblogstash";

    // Dependencies
    this.dependencies 		= [ "cbelasticsearch" ];

    /**
     * Configure Module
     */
    function configure(){
        settings = {
            "enableAPI" 		: getSystemSetting( "LOGSTASH_ENABLE_API", true ),
            "enableAppenders" 	: getSystemSetting( "LOGSTASH_ENABLE_APPENDERS", true ),
            "transmission" 		: getSystemSetting( "LOGSTASH_TRANSMISSION_METHOD", "direct" ),
            // only used if the transmission setting is `api`
            "apiUrl" 			: getSystemSetting( "LOGSTASH_API_URL", "" ),
            // Regex used to whitelist remote hosts allowed to transmit to the API - by default only localhost is allowed to transmit
            "apiWhitelist" 		: getSystemSetting( "LOGSTASH_API_WHITELIST", "127.0.0.1" ),
            // a user-provided API token - which must match the token configured on the remote API microservice leave empty if using IP whitelisting
            "apiAuthToken" 		: getSystemSetting( "LOGSTASH_API_TOKEN", "" ),
            // Min/Max levels for appender
            "levelMin" 			: getSystemSetting( "LOGSTASH_LEVEL_MIN", "FATAL" ),
            "levelMax" 			: getSystemSetting( "LOGSTASH_LEVEL_MAX", "ERROR" )
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
            { class="cblogstash.interceptors.APISecurity" }
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
        if( settings.enableAppenders ){
            loadAppenders();
        }
    }

    /**
     * Fired when the module is unregistered and unloaded
     */
    function onUnload(){}

    /**
     * Load LogBox Appenders
     */
    private function loadAppenders(){

        // Get config
        var logBoxConfig 	= logBox.getConfig();
        var rootConfig 		= logBoxConfig.getRoot();

        logBoxConfig.appender(
            name 		= 'logstash_appender',
            class 		= settings.transmission == "direct" ? "cbelasticsearch.models.logging.LogstashAppender" : "cblogstash.models.logging.APIAppender",
            properties  = settings,
            levelMin 	= settings.levelMin,
            levelMax 	= settings.levelMax
        );

        logBoxConfig.root(
            levelMin = rootConfig.levelMin,
            levelMax = rootConfig.levelMax,
            appenders= listAppend( rootConfig.appenders, 'logstash_appender')
        );

        // Store back config
        logBox.configure( logBoxConfig );
    }

}
