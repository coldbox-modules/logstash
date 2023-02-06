component extends="cbelasticsearch.models.logging.LogstashAppender"{

	/**
     * Write an entry into the appender.
	 * @logEvent - in this case the event will be a struct provided by the
     */
    public void function logMessage(required any logEvent, string dataStream ) output=false {
		if( isNull( arguments.dataStream ) ){
			arguments.dataStream = getProperty( "dataStream" );
		}

		if( isObject( arguments.logEvent ) ){
			throw(
				type="logstash.UsageException",
				message="The logEvent passed to the logMessage function is of an incorrect type.  This appender requires a full log message struct to perform its operation. Try using the `APIAppender` instead."
			);
		}

		newDocument().new(
			index = arguments.dataStream,
			properties = arguments.logEvent
		)
		.create();
    }

}