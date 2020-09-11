component extends="cbelasticsearch.models.logging.LogstashAppender"{

	/**
     * Write an entry into the appender.
	 * @logEvent - in this case the event will be a struct provided by the
     */
    public void function logMessage(required any logEvent) output=false {
		ensureIndex();
		if( isInstanceOf( logEvent, "LogEvent" ) ){
			throw(
				type="cblogstash.UsageException",
				message="The logEvent passed to the logMessage function is of an incorrect type.  This appender requires a full log message struct to perform its operation. Try using the `APIAppender` instead."
			);
		}
		var category 	= getProperty( "defaultCategory" );
		var cmap 		= "";
		var cols 		= "";

		if( isInstanceOf( logEvent, "LogEvent" ) ) return super.logMessage( logEvent );

		var logEntry = {
			"application"  : getProperty( "applicationName" ),
			"release"      : javacast( "string", getProperty( "releaseVersion" ) ),
			"type"         : logEvent.type ?: "api",
			"level"        : logEvent.level ?: "ERROR" ,
			"severity"     : logEvent.severity ?: 1,
			"category"     : logEvent.category ?: category,
			"timestamp"    : logEvent.keyExists( "timestamp" ) ? dateTimeFormat( parseDateTime( logEvent.timestamp ), "yyyy-mm-dd'T'hh:nn:ssZZ" ):  dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" ),
			"appendername" : getName(),
			"component"    : logEvent.component ?: "",
			"message"      : logEvent.message ?: "",
			"stacktrace"   : logEvent.keyExists( "stacktrace" )
								? ( isSimpleValue( logEvent.stacktrace ) ? listToArray( logEvent.stacktrace, "#chr(13)##chr(10)#" ) : logEvent.stacktrace )
								: javacast( "null", 0 ),
			"extrainfo"    : logEvent.extrainfo ?: javacast( "null", 0 )
		};

		logEntry[ "snapshot" ] = logEvent.snapshot ?: {};
		logEntry[ "event" ] = logEvent.event ?: {};
		logEntry[ "userinfo" ] = logEvent.keyExists( "userinfo" )
									? ( !isSimpleValue( logEvent.userinfo ) ? application.wirebox.getInstance( "Util@cbelasticsearch" ).toJSON( logEvent.userInfo ) : logEvent.userInfo )
									: "";

		newDocument().new(
			index=getRotationalIndexName(),
			properties=logEntry
		).setId( instance.uuid.randomUUID() )
		.save();
    }

}