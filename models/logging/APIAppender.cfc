component extends="cbelasticsearch.models.logging.LogstashAppender" {

	property name="hyper"            inject="HyperBuilder@Hyper";
	property name="logStashSettings" inject="coldbox:moduleSettings:logstash";

	/**
	 * Write an entry into the appender.
	 */
	public void function logMessage( required any logEvent ) output=false{
		if ( !len( logStashSettings.apiUrl ) ) {
			throw(
				type    = "logstash.InvalidConfiguration",
				message = "An API URL has not been configured.  This appender may not be used."
			);
		}

		var logObj = marshallLogObject( argumentCollection = arguments );

		var requestObj = hyper
			.new()
			.setMethod( "POST" )
			.setThrowOnError( true )
			.setUrl( logStashSettings.apiUrl )
			.setBody( {
				"entry"      : logObj,
				"dataStream" : getProperty( "dataStream" )
			} )
			.asJSON();

		if ( len( logStashSettings.apiAuthToken ) ) {
			requestObj.setHeader(
				"Authorization",
				"Bearer " & logStashSettings.apiAuthToken
			);
		}

		try {
			requestObj.send();
		} catch ( any e ) {
			throw(
				type         = "logstash.APITransmissionException",
				message      = "There was an error communicating with the LogStash API endpoint.  The message received was #e.message#",
				errorCode    = e.errorCode,
				extendedInfo = e.stacktrace
			);
		}
	}

}
