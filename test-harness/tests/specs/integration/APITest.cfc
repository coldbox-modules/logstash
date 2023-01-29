/*******************************************************************************
*	Integration Test as BDD (CF10+ or Railo 4.1 Plus)
*
*	Extends the integration class: coldbox.system.testing.BaseTestCase
*
*	so you can test your ColdBox application headlessly. The 'appMapping' points by default to
*	the '/root' mapping created in the test folder Application.cfc.  Please note that this
*	Application.cfc must mimic the real one in your root, including ORM settings if needed.
*
*	The 'execute()' method is used to execute a ColdBox event, with the following arguments
*	* event : the name of the event
*	* private : if the event is private or not
*	* prePostExempt : if the event needs to be exempt of pre post interceptors
*	* eventArguments : The struct of args to pass to the event
*	* renderResults : Render back the results of the event
*******************************************************************************/
component extends="coldbox.system.testing.BaseTestCase"{
	this.loadColdbox = true;
	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		super.beforeAll();
		// do your own stuff here

		debug( application.cbController.getModuleService().isModuleRegistered( "logstash" ) );

		var moduleSettings = getWirebox().getInstance( "coldbox:moduleSettings:logstash" );
		variables.baseSettings = duplicate( moduleSettings );

		// create an error message
		try{
			var a = b;
		} catch( any e ){
			variables.errorEntry = e;
		}

		var logstashAppender = createMock( "cbelasticsearch.models.logging.LogstashAppender" );
		logstashAppender.init( "MockLogstashAppender" );
		makePublic( logstashAppender, "getRotationalIndexName", "getRotationalIndexName" );

		variables.logEntry = {
			"application"  : "logstash-test-suite",
			"index"        :  logstashAppender.getRotationalIndexName(),
			"release"      : "1",
			"type"         : "api",
			"level"        : "ERROR" ,
			"severity"     : 1,
			"category"     : "tests",
			"timestamp"    : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" ),
			"component"    : getMetadata( this ).name,
			"message"      : errorEntry.message,
			"stacktrace"   : errorEntry.stacktrace,
			"extrainfo"    : errorEntry.stacktrace,
			"snapshot"     : {},
			"userinfo"     : { "username" : "tester" },
			"event"        : { "foo" : "bar" }
		};

	}

	function afterAll(){
		// do your own stuff here
		super.afterAll();
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "API Suite", function(){

			beforeEach(function( currentSpec ){
				setup();
			});

			afterEach( function( currentSpec ){
				getWirebox().getInstance( "coldbox:moduleSettings:logstash" ).enableAPI = true;
				getWirebox().getInstance( "coldbox:moduleSettings:logstash" ).apiAuthToken = "";
			} );

			it( "Tests that the create method will return an invalid event if the configuration is set to disable the API", function(){
				getWirebox().getInstance( "coldbox:moduleSettings:logstash" ).enableAPI = false;

				var testEvent = newEventArgs( "POST" );
				testEvent.rc.entry = logEntry;


				var event = execute(
					route="/logstash/api/logs",
					eventArgs=testEvent,
					renderResults=false
				);

				var prc = event.getCollection( private=true );
				expect( prc ).toHaveKey( "response" );
				debug( prc.response );
				expect( prc.response.getStatusCode() ).toBe( 405 );


			} );

			xit( "Tests that the create method will return Authorization failure if the IP address is incorrect", function(){

				var testEvent = newEventArgs( "POST" );
				testEvent.rc.entry = logEntry;


				var event = execute(
					route="/logstash/api/logs",
					eventArgs=testEvent,
					renderResults=false
				);

				var prc = event.getCollection( private=true );
				expect( prc ).toHaveKey( "response" );
				debug( prc.response );
				expect( prc.response.getStatusCode() ).toBe( 403 );
			} );

			it( "Tests that the create method will return Authentication failure if the token is incorrect", function(){
				getWirebox().getInstance( "coldbox:moduleSettings:logstash" ).enableAPI = true;
				getWirebox().getInstance( "coldbox:moduleSettings:logstash" ).apiAuthToken = createUUID();

				var testEvent = newEventArgs( "POST" );
				testEvent.rc.entry = logEntry;

				var event = execute(
					route="/logstash/api/logs",
					eventArgs=testEvent,
					renderResults=false
				);

				var prc = event.getCollection( private=true );
				expect( prc ).toHaveKey( "response" );
				debug( prc.response );
				expect( prc.response.getStatusCode() ).toBe( 401 );
			} );

			it( "Tests that the create method can create a log entry", function(){
				getWirebox().getInstance( "coldbox:moduleSettings:logstash" ).enableAPI = true;
				getWirebox().getInstance( "coldbox:moduleSettings:logstash" ).apiAuthToken = "";

				var testEvent = newEventArgs( "POST" );
				testEvent.rc.entry = logEntry;


				var event = execute(
					route="/logstash/api/logs",
					eventArgs=testEvent,
					renderResults=false
				);

				var prc = event.getCollection( private=true );
				expect( prc ).toHaveKey( "response" );
				expect( prc.response.getStatusCode() ).toBe( 201 );
				debug( prc.response.getData() );
				expect( prc.response.getData() ).toBeStruct()
												.toHaveKey( "accepted" );


			} );


		});

	}

	function newEventArgs( method = "GET" ) {

		//clear out all request keys
		for( var key in request ){
			if( findNoCase( "wirebox:", key ) ){
				structDelete( REQUEST, key );
			}
		}

		setup();

		var event = getRequestContext();
		prepareMock( event )
			.$( "getHTTPMethod", arguments.method )
			.$( method = "getHTTPHeader", callback = function( string name ) {
				if ( arguments.name == "X-Requested-With" ){
					return "XMLHttpRequest";
				}
				return "";
			} );

		var rc = event.getCollection();
		var prc = event.getCollection( private=true );


		return {
			"event":event,
			"rc":rc,
			"prc":prc
		};
	}

}
