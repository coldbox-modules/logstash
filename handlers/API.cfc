component extends="BaseHandler"{
	property name="moduleSettings" inject="coldbox:modulesettings:cblogstash";

	function create( event, rc, prc ){

		if( !structKeyExists( rc, "entry" ) ){
			throw(
				type="cblogstash.ExpectationFailedException",
				message="The payload provided to the API log creation event did not contain a valid entry"
			);
		}

		var configOptions = duplicate( rc.entry );
		structAppend( configOptions, moduleSettings, false );

		var logger = new cblogstash.models.logging.APIEventAppender(
			name = "cbLogstash_api_appender",
			properties = configOptions
		);

		logger.logMessage( rc.entry );

		prc.response.setData( { "accepted" : true, "error" : false } ).setStatusCode( 201 );

	}
}