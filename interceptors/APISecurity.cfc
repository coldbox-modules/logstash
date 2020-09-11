component{

	void function preEvent( event, interceptData, buffer, rc, prc ) eventPattern="^cblogstash:api*\."{
		// we do not inject this setting for interceptor testability
		var moduleSettings = getController().getSettingStructure().moduleSettings.cbLogstash;

		if( !moduleSettings.enableAPI  ){
			event.overrideEvent( "cblogstash:API.onInvalidHTTPMethod");
		} else if( !reFind( moduleSettings.apiWhitelist, CGI.REMOTE_HOST ) ) {
			event.overrideEvent( "cblogstash:API.onAuthorizationFailure" );
		} else if( len( moduleSettings.apiAuthToken ) ){
			var token = listLast( event.getHTTPHeader( "Authorization", "" ) );
			if( token != moduleSettings.apiAuthToken ){
				event.overrideEvent( "cblogstash:API.onAuthenticationFailure" );
			}
		}
	}

}