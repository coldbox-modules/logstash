component {

	function configure(){

		var moduleSettings = controller.getWirebox().getInstance( "coldbox:moduleSettings:logstash" );

		var apiEnabled = moduleSettings.apiEnabled ?: true;

		if( apiEnabled ){
			route( "/api/logs" )
					.withAction( {
						"HEAD"		: "onInvalidHTTPMethod",
						"OPTIONS"	: "onInvalidHTTPMethod",
						"GET"   	: "onInvalidHTTPMethod",
						"POST"  	: "create",
						"DELETE"	: "onInvalidHTTPMethod",
						"PUT"   	: "create",
						"PATCH" 	: "onInvalidHTTPMethod"
					} )
					.toHandler( "API" );
		}
	}

}
