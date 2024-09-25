/**
* The base model test case will use the 'model' annotation as the instantiation path
* and then create it, prepare it for mocking and then place it in the variables scope as 'model'. It is your
* responsibility to update the model annotation instantiation path and init your model.
*/
component extends="coldbox.system.testing.BaseTestCase"{

	/*********************************** LIFE CYCLE Methods ***********************************/
	this.loadColdbox = true;

	function beforeAll(){
		super.beforeAll();

		variables.model = prepareMock( new logstash.models.logging.APIAppender(
			"APIAppenderTest",
			{
				"applicationName"       : "testspecs",
				"dataStream"            : "logstash-api-appender-tests",
				"dataStreamPattern"     : "logstash-api-appender-tests*",
				"componentTemplateName" : "logstash-api-appender-component",
				"indexTemplateName"     : "logstash-api-appender-tests",
				"ILMPolicyName"         : "logstash-api-appender-tests",
				"releaseVersion"        : "1.0.0",
				"userInfoUDF"           : function(){
											   return {
												   "name" : "tester",
												   "full_name" : "Test Testerson",
												   "username" : "tester"
											   };
										  }
		   }
		) );


		makePublic( variables.model, "getProperty", "getProperty" );

		variables.model.onRegistration();

		variables.loge = getMockBox().createMock(className="coldbox.system.logging.LogEvent");

		// create an error message
		try{
			var a = b;
		} catch( any e ){

			variables.loge.init(
				message = len( e.detail ) ? e.detail : e.message,
				severity = 0,
				extraInfo = e.StackTrace,
				category = e.type
			);
		}

	}

	function afterAll(){
		var esClient = variables.model.getClient();
		if( esClient.dataStreamExists( variables.model.getProperty( "dataStream" ) ) ){
			esClient.deleteDataStream( variables.model.getProperty( "dataStream" ) );
		}

		if( esClient.indexTemplateExists( variables.model.getProperty( "indexTemplateName" ) ) ){
			esClient.deleteIndexTemplate( variables.model.getProperty( "indexTemplateName" ) );
		}

		if( esClient.componentTemplateExists( variables.model.getProperty( "componentTemplateName" ) ) ){
			esClient.deleteComponentTemplate( variables.model.getProperty( "componentTemplateName" ) );
		}

		if( esClient.ILMPolicyExists( variables.model.getProperty( "ILMPolicyName" ) ) ){
			esClient.deleteILMPolicy( variables.model.getProperty( "ILMPolicyName" ) );
		}

		super.afterAll();
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "logstash.models.logging.APIAppender Suite", function(){
			beforeEach( function(){
				var searchBuilder = getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new( variables.model.getProperty( "dataStream" ) ).setQuery( { "match_all" : {} });
				variables.model.getClient().deleteByQuery( searchBuilder, true );
			} )
			it( "Can create a log message", function(){
				// create a test error
				variables.model.logMessage( variables.loge );

				sleep( 1000 );

				var documents = getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new( variables.model.getProperty( "dataStream" ) ).setQuery( { "match_all" : {} }).execute().getHits();

				expect( documents.len() ).toBeGT( 0 );

				var logMessage = documents[ 1 ].getMemento();

				debug( logMessage  );

				expect( logMessage )
					.toHaveKey( "error" )
					.toHaveKey( "user" )
					.toHaveKey( "event" );

				expect( logMessage.user ).toHaveKey( "info" );

				expect( isJSON( logMessage.user.info ) ).toBeTrue();
				expect( deserializeJSON( logMessage.user.info ) ).toHaveKey( "username" );

			});

		});

	}

}
