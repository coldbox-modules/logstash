component extends="BaseHandler"{
	property name="moduleSettings" inject="coldbox:modulesettings:logstash";

	function create( event, rc, prc ){

		if( !structKeyExists( rc, "entry" ) ){
			throw(
				type="logstash.ExpectationFailedException",
				message="The payload provided to the API log creation event did not contain a valid entry"
			);
		}

		var configOptions = duplicate( rc.entry );
		structAppend( configOptions, moduleSettings, false );

		param configOptions.index = moduleSettings.indexPrefix;

		var logger = new logstash.models.logging.APIEventAppender(
			name = "logstash_api_appender",
			properties = configOptions
		);

		logger.logMessage( rc.entry );

		prc.response.setData( { "accepted" : true, "error" : false } ).setStatusCode( 201 );

	}
	
}