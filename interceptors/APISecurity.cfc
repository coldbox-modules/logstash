component{

	void function preEvent( event, interceptData, buffer, rc, prc ) eventPattern="^logstash:api*\."{
		// we do not inject this setting for interceptor testability
		var moduleSettings = getController().getSettingStructure().moduleSettings.logstash;

		if( !moduleSettings.enableAPI  ){
			event.overrideEvent( "logstash:API.onInvalidHTTPMethod");
		} else if( !reFind( moduleSettings.apiWhitelist, CGI.REMOTE_HOST ) ) {
			event.overrideEvent( "logstash:API.onAuthorizationFailure" );
		} else if( len( moduleSettings.apiAuthToken ) ){
			var token = listLast( event.getHTTPHeader( "Authorization", "" ) );
			if( token != moduleSettings.apiAuthToken ){
				event.overrideEvent( "logstash:API.onAuthenticationFailure" );
			}
		}
	}

}