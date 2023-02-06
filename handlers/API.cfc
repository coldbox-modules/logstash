component extends="BaseHandler"{
	property name="moduleSettings" inject="coldbox:modulesettings:logstash";
	property name="eventAppender" inject="EventAppender@logstash";

	function create( event, rc, prc ){

		if( !structKeyExists( rc, "entry" ) || !isStruct( rc.entry ) ){
			throw(
				type="logstash.ExpectationFailedException",
				message="The payload provided to the API log creation event did not contain a valid entry"
			);
		}

		eventAppender.logMessage( rc.entry, rc.keyExists( "dataStream" ) ? rc.dataStream : javacast( "null", 0 ) );

		prc.response.setData( { "accepted" : true, "error" : false } ).setStatusCode( 201 );

	}

}