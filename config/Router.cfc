component {

	function configure(){
		var apiEnabled = controller.getModuleSettings( "logstash", "apiEnabled", true );

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
