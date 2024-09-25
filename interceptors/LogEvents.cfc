component {

	property name="appenderService" inject="AppenderService@cbelasticsearch";


	function writeToAppender( event, rc, prc, interceptData ){
		if( !interceptData.keyExists( "appender" ) ){
			throw( type="InvalidArgument", message="The 'appender' key is required in the intercept data.  Could not continue." );
		} else if( !interceptData.keyExists( "message" ) ){
			throw( type="InvalidArgument", message="The 'message' key is required in the intercept data.  Could not continue." );
		}

		param interceptData.extraInfo = {};
		param interceptData.severity = "INFO";

		appenderService.logToAppender(
			interceptData.appender,
			interceptData.message,
			interceptData.severity,
			interceptData.extraInfo
		);

	}

}