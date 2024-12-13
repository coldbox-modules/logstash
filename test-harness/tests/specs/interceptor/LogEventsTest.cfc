component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		this.loadColdbox = true;
		super.beforeAll();
		setup();
		variables.esClient    = getWirebox().getInstance( "Client@cbelasticsearch" );
		variables.interceptor = new logstash.interceptors.LogEvents();
		getWirebox().autowire( variables.interceptor );

		variables.appenderName    = "logstashLogEventsTest";
		variables.appenderService = getWirebox().getInstance( "AppenderService@cbelasticsearch" );
		appenderService.createDetachedAppender(
			appenderName,
			{
				// The data stream name to use for this appenders logs
				"dataStreamPattern"     : "logs-coldbox-#lCase( appenderName )#*",
				"dataStream"            : "logs-coldbox-#lCase( appenderName )#",
				"ILMPolicyName"         : "cbelasticsearch-logs-#lCase( appenderName )#",
				"indexTemplateName"     : "cbelasticsearch-logs-#lCase( appenderName )#",
				"componentTemplateName" : "cbelasticsearch-logs-#lCase( appenderName )#",
				"pipelineName"          : "cbelasticsearch-logs-#lCase( appenderName )#",
				"indexTemplatePriority" : 151,
				"retentionDays"         : 1,
				// The name of the application which will be transmitted with the log data and used for grouping
				"applicationName"       : "Logstash Detached Interception Appender Logs",
				// The max shard size at which the hot phase will rollover data
				"rolloverSize"          : "1gb"
			}
		);
	}

	function afterAll(){
		var appender = appenderService.getAppender( variables.appenderName );
		if ( !isNull( appender ) ) {
			if ( esClient.dataStreamExists( appender.getProperty( "dataStream" ) ) ) {
				esClient.deleteDataStream( appender.getProperty( "dataStream" ) );
			}
			if ( esClient.indexTemplateExists( appender.getProperty( "indexTemplateName" ) ) ) {
				esClient.deleteIndexTemplate( appender.getProperty( "indexTemplateName" ) );
			}

			if ( esClient.componentTemplateExists( appender.getProperty( "componentTemplateName" ) ) ) {
				esClient.deleteComponentTemplate( appender.getProperty( "componentTemplateName" ) );
			}

			if ( esClient.ILMPolicyExists( appender.getProperty( "ILMPolicyName" ) ) ) {
				esClient.deleteILMPolicy( appender.getProperty( "ILMPolicyName" ) );
			}
		}

		super.afterAll();
	}

	function run(){
		describe( "Perform actions on detached appender", function(){
			it( "Tests the ability to log a message through the interception point", function(){
				var appender        = appenderService.getAppender( variables.appenderName );
				var dataStreamCount = getDataStreamCount( appender.getProperty( "dataStreamPattern" ) );
				var event           = getMockRequestContext();
				var rc              = event.getCollection();
				var prc             = event.getPrivateCollection();
				variables.interceptor.writeToAppender(
					event,
					rc,
					prc,
					{
						"appender" : variables.appenderName,
						"message"  : "Test message"
					}
				);
				sleep( 1000 );
				expect( getDataStreamCount( appender.getProperty( "dataStreamPattern" ) ) ).toBe( dataStreamCount + 1 );
			} );
		} );
	}

	function getDataStreamCount( required string dataStreamPattern ){
		return getWirebox()
			.getInstance( "SearchBuilder@cbelasticsearch" )
			.setIndex( dataStreamPattern )
			.setQuery( { "match_all" : {} } )
			.count();
	}

}
