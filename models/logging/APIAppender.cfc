component extends="cbelasticsearch.models.logging.LogstashAppender"{
	property name="hyper" inject="HyperBuilder@Hyper";
	property name="logStashSettings" inject="coldbox:moduleSettings:logstash";

	/**
     * Write an entry into the appender.
     */
    public void function logMessage(required any logEvent) output=false {

		if( !len( logStashSettings.apiUrl ) ){
			throw(
				type="logstash.InvalidConfiguration",
				message="An API URL has not been configured.  This appender may not be used."
			);
		}
		// we need to maintain all of this boilerplate code in two places because the AbstractAppender is interfaced in Coldbox 5.x
		var category 	= getProperty( "defaultCategory" );
		var cmap 		= "";
		var cols 		= "";
		var loge 		= arguments.logEvent;
		var message 	= loge.getMessage();

		var logObj = {
			"index"        : getProperty( "index" ),
			"application"  : getProperty( "applicationName" ),
			"release"      : javacast( "string", getProperty( "releaseVersion" ) ),
			"type"         : "server",
			"level"        : severityToString( loge.getSeverity() ),
			"severity"     : loge.getSeverity(),
			"category"     : category,
			"timestamp"    : dateTimeFormat( loge.getTimestamp(), "yyyy-mm-dd'T'hh:nn:ssZZ" ),
			"appendername" : getName(),
			"component"    : "test",
			"message"      : loge.getMessage(),
			"stacktrace"   : isSimpleValue( loge.getExtraInfo() ) ? listToArray( loge.getExtraInfo(), "#chr(13)##chr(10)#" ) : javacast( "null", 0 ),
			"extrainfo"    : !isSimplevalue( loge.getExtraInfo() ) ? loge.getExtraInfoAsString() : javacast( "null", 0 )
		};

		if( logObj.severity < 2 ){

			logObj[ "snapshot" ] = {
				"template"       : CGI.CF_TEMPLATE_PATH,
				"path"           : CGI.PATH_INFO,
				"host"           : CGI.HTTP_HOST,
				"referer"        : CGI.HTTP_REFERER,
				"browser"        : CGI.HTTP_USER_AGENT,
				"remote_address" : CGI.REMOTE_ADDR
			};

			if( structKeyExists( application, "cbController" ) ){
				var event = application.cbController.getRequestService().getContext();
				logObj[ "event" ] = {
					"name"		  : (event.getCurrentEvent() != "") ? event.getCurrentEvent() :"N/A",
					"route"		  : (event.getCurrentRoute() != "") ? event.getCurrentRoute() & ( event.getCurrentRoutedModule() != "" ? " from the " & event.getCurrentRoutedModule() & "module router." : ""):"N/A",
					"routed_url"  : (event.getCurrentRoutedURL() != "") ? event.getCurrentRoutedURL() :"N/A",
					"layout"	  : (event.getCurrentLayout() != "") ? event.getCurrentLayout() :"N/A",
					"module"	  : event.getCurrentLayoutModule(),
					"view"		  : event.getCurrentView(),
					"environment" : application.cbController.getSetting( "environment" )
				};

			}

		}
		if( propertyExists( "userInfoUDF" ) ){
			var udf = getProperty( "userInfoUDF" );

			if( isClosure( udf ) ){
				try{
					logObj[ "userinfo" ] = udf();
					if( !isSimpleValue( logObj.userinfo ) ){
						logObj.userinfo = variables.util.toJSON( logObj.userinfo );
					}
				} catch( any e ){
					logObj[ "userinfo" ] = "An error occurred when attempting to run the userInfoUDF provided.  The message received was #e.message#";
				}
			}
		}

		preflightLogEntry( logObj );

		var requestObj = hyper.new()
				.setMethod( "POST" )
				.setThrowOnError( true )
				.setUrl( logStashSettings.apiUrl )
				.setBody( { "entry" : logObj } )
				.asJSON();

		if( len( logStashSettings.apiAuthToken ) ){
			requestObj.setHeader( "Authorization", "Bearer " & logStashSettings.apiAuthToken );
		}

		try{
			requestObj.send();
		} catch( any e ){
			throw(
				type = "logstash.APITransmissionException",
				message = "There was an error communicating with the LogStash API endpoint.  The message received was #e.message#",
				errorCode = e.errorCode,
				extendedInfo = e.stacktrace
			);
		}

    }

}