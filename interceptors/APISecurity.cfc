component{
	property name="moduleSettings" inject="coldbox:moduleSettings:logstash";

	void function preEvent( event, interceptData, buffer, rc, prc ) eventPattern="^logstash:api*\."{

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