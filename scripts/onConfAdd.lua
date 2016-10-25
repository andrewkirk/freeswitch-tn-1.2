-- =========================================================================
--              ____             __   _       _     _ 
--  ___  _ __  / ___|___  _ __  / _| / \   __| | __| |
-- / _ \| '_ \| |   / _ \| '_ \| |_ / _ \ / _` |/ _` |
--| (_) | | | | |__| (_) | | | |  _/ ___ \ (_| | (_| |
-- \___/|_| |_|\____\___/|_| |_|_|/_/   \_\__,_|\__,_|
--                                                    
-- =========================================================================

api = freeswitch.API()
json = require('json')

-- ==========================================================
-- Initialize Variables STATIC
-- ==========================================================


obSessionString = null;

modName = "onConfAdd"
prevUuid = argv[1]
myUuid = argv[1]

appData = {}  -- Needs to be global 
logToDisk               = api:executeString("uuid_getvar " .. prevUuid .. " fsd_logToDisk")
debug                   = api:executeString("uuid_getvar " .. prevUuid .. " fsd_debug")

-- Overwrite debug for now
debug = true;
debugUuid               = prevUuid;

    confUuid                = api:executeString("uuid_getvar " .. prevUuid .. " fsd_conf_uuid");

    if confUuid == "_undef_" then
        -- This only happens the first time!! 
        confUuid = prevUuid;
    else
        debugUuid = confUuid;
    end


uuid_exists             = api:executeString("uuid_exists " .. prevUuid );
new_uuid                = api:executeString("create_uuid");

-- ==========================================================
-- Shared Logging and Helper Functions 
--  Set modName, myUuid and debugUuid BEFORE this!!
-- ==========================================================
dofile("/etc/freeswitch/scripts/logAndHelper.lua")


function errorOut() 

    -- Put code in here to quit !!

end

-- ==========================================================
-- Build Dialer Strings
-- ==========================================================

function createComboObString( )   -- Terminate to Client/App




    obSessionString = string.format(
        "<execute_on_answer='lua /etc/freeswitch/scripts/onConfAnswer.lua %s %s'" ..
        ",fsd_conf_uuid=%s" ..
        ",originate_timeout=%i" ..
        ",set_zombie_exec,session_in_hangup_hook=true,api_hangup_hook='lua onHupTest.lua'" ..
        ",ignore_early_media=true" ..
        ",caller_id_type=pid,origination_caller_id_number=%s" ..
        ",fsd_toTN=%s,fsd_fromTN=%s" ..
        ",fsd_leg=ob" ..
        ",fsd_on_conf_answer_uri='%s',fsd_on_call_end_uri='%s'" ..
        ",fsd_on_prepaid_timer_time=%i,fsd_on_prepaid_timer_uri='%s'" ..
        ",fsd_call_orig_type=%s" ..
        ",fsd_call_timeout=%i,fsd_to_address=%s" ..
        ",fsd_uuid=%s,fsd_uuid_bleg_to_kill=%s" ..
        ",fsd_logToDisk=%s,fsd_debug=%s" ..
        ",fsd_customer_name=%s" ..
		",fsd_default_domain=%s,fsd_on_conf_add_uri=%s" ..
		",fsd_cops_tt=%s,fsd_cops_ct=%s" ..
        ">%s",
        tostring( new_uuid ), tostring( prevUuid ),
        tostring( confUuid ),
        tonumber( answerTimeout ),
        tostring( appData.caller_id ), 
        tostring( toTN ), tostring( fromTN ), 
        tostring( appData.on_conf_answer_uri ), tostring( appData.on_call_end_uri ),
        tonumber( appData.on_prepaid_timer_time ~= nil and appData.on_prepaid_timer_time or 0 ), tostring( appData.on_prepaid_timer_uri ),
        tostring( appData.call_orig_type ), 
        tonumber( appData.call_timeout ), tostring( appData.to_address ),
        tostring( prevUuid ), tostring( prevUuid ), 
        tostring( appData.logToDisk ), tostring( appData.debug ),
        tostring( customerName ),
        tostring( default_domain ), tostring( baseOnConfAddURL ),
		tostring( cops_tt ), tostring( cops_ct ),
        tostring( clientString )
        

    );

        -- obSessionString = string.format("%s%s", 
            -- obSessionString,  table.concat( appData['obClientArray'], ":_:" ) )


    fsLogInfo( "DialString == " .. obSessionString )

end


-- ==========================================================
-- Main
-- ==========================================================

fsLogInfo( "*******  START of onConfAdd.lua  *****" )


if uuid_exists then

    
    -- fsLogDebug( api:executeString('uuid_dump ' .. prevUuid ));

    baseOnConfAddURL        = api:executeString("uuid_getvar " .. prevUuid .. " fsd_on_conf_add_uri");
    cops_tt                 = api:executeString("uuid_getvar " .. prevUuid .. " fsd_cops_tt");
    cops_ct                 = api:executeString("uuid_getvar " .. prevUuid .. " fsd_cops_ct");
    customerName            = api:executeString("uuid_getvar " .. prevUuid .. " fsd_customer_name");
    default_domain          = api:executeString("uuid_getvar " .. prevUuid .. " fsd_default_domain");
    confUuid                = api:executeString("uuid_getvar " .. prevUuid .. " fsd_conf_uuid");
    toTN                = api:executeString("uuid_getvar " .. prevUuid .. " fsd_toTN");
    fromTN                = api:executeString("uuid_getvar " .. prevUuid .. " fsd_fromTN");

    if confUuid == "_undef_" then
        -- This only happens the first time!! 
        confUuid = prevUuid;
    end

    -- -----------------------------------------------------------------------
    -- Send Data to Server and get JSON response 
	-- -----------------------------------------------------------------------
    local postData = "newUuid=" .. url_encode( new_uuid )
    .. "&prevUuid=" .. url_encode( prevUuid )
    .. "&confUuid=" .. url_encode( confUuid );

    fsLogWarn( "** " .. baseOnConfAddURL .. " post " .. postData );

    post_response = api:execute("curl", baseOnConfAddURL .. " post " .. postData );
    fsLogDebug( " post_response = " .. post_response );


    if isErr( post_response ) then

        -- -----------------------------------------------------------------------
        -- If curl response starts with -ERR
        -- -----------------------------------------------------------------------

        fsLogError( string.format("*******  post_response  ERROR: %s  ********",
            tostring( post_response ) ))

        -- DO MORE ERROR STUFF HERE  

    else

        appData = json.decode( post_response )

        -- Print out the JSON data we got back

        fsLogDebug( "\n----- appData Before Processing ------\n" 
            ..  to_string( appData ) 
            .. "\n--------------------------");

    
        if appData.allow_call ~= nil and (tonumber( appData.allow_call ) == 1) then
        

            InConf = api:executeString("uuid_getvar " .. prevUuid .. " fsd_conf_uuid");

            fsLogDebug( "\n----- InConf = " .. InConf .. " ------\n" );

            if InConf == "_undef_" then

                local trnferStr = "uuid_transfer " .. prevUuid .. " -both conf_" .. confUuid .. " XML enflick";

                fsLogDebug( "\n----- TRANSFER TO BRIDGE ON FIRST TIME ONLY  ------\n" 
                ..  to_string( trnferStr ) 
                .. "\n--------------------------");
    
                api:executeString( trnferStr );
                api:executeString("uuid_setvar " .. prevUuid .. " fsd_conf_uuid " .. confUuid );
            else
                confUuid = api:executeString("uuid_getvar " .. confUuid .. " fsd_conf_uuid");

                fsLogDebug( "\n----- no TRANSFER TO BRIDGE this is not the first time ------\n" );
            end



            if appData.to_address == nil and appData.to_addresses == nil then
                fsLogError( "*******  Manditory JSON value to_address not returned *****" )
                errorOut();
            end

            if appData.from_address == nil then
                appData.from_address = api:executeString("uuid_getvar " .. prevUuid .. " fsd_from_address");
            end


            -- -----------------------------------------------------------------------
            -- Optional Data - Check or set defaults
            -- -----------------------------------------------------------------------
   
            if appData.logToDisk == nil then
                appData.logToDisk = api:executeString("uuid_getvar " .. prevUuid .. " fsd_logToDisk");
            end

            if appData.debug == nil then
                appData.debug = api:executeString("uuid_getvar " .. prevUuid .. " fsd_debug");
            end

            if appData.caller_id == nil then
                appData.caller_id = api:executeString("uuid_getvar " .. prevUuid .. " fsd_caller_id"); 
            end

            if appData.call_timeout == nil then
                appData.call_timeout = api:executeString("uuid_getvar " .. prevUuid .. " fsd_call_timeout");
            end

            if appData.on_conf_answer_uri == nil then
                appData.on_conf_answer_uri = api:executeString("uuid_getvar " .. prevUuid .. " fsd_on_conf_answer_uri");
            end

            if appData.on_prepaid_timer_uri == nil then
                appData.on_prepaid_timer_uri = api:executeString("uuid_getvar " .. prevUuid .. " fsd_on_prepaid_timer_uri");
            end

            if appData.on_prepaid_timer_time == nil then
                appData.on_prepaid_timer_time = api:executeString("uuid_getvar " .. prevUuid .. " fsd_on_prepaid_timer_time");
            end

            if appData.on_call_end_uri == nil then
                appData.on_call_end_uri = api:executeString("uuid_getvar " .. prevUuid .. " fsd_on_call_end_uri");
            end


            answerTimeout = answerTimeout ~= nil and answerTimeout or 20;
            pstnAnswerTimeout = pstnAnswerTimeout ~= nil and pstnAnswerTimeout or 20;

            if tostring( appData.p_or_s ) == "s" then  -- softphone 
                appData.call_term_type = "softphone"
                fsLogWarn( "Terminating to Softphone" )

                clientString = string.format(
                    "{origination_uuid=%s,sip_h_X-Route-Helper=%s" .. 
                    ",fsd_call_term_type=client" ..
                    ",leg_timeout=%i" ..
                    ",sip_invite_to_uri=<sip:%s@%s>}" ..
                    "sofia/outbound_5060/%s@%s",
                    new_uuid, default_domain,
                    tonumber( answerTimeout ),
                    tostring( appData.to_address ), tostring( default_domain ),
        
                    tostring( appData.to_address ), cops_ct )

                -- appData.to_addresses[1] = string.format("%s@%s", appData.to_address, default_domain)

                createComboObString()
            elseif tostring( appData.p_or_s ) == "p" then  -- pstn 

                appData.call_term_type = "pstn"
                fsLogWarn( "Terminating to PSTN" )

               clientString = string.format(
                    "{origination_uuid=%s,sip_h_X-Route-Helper=%s" .. 
                    ",leg_timeout=%i" ..
                    ",fsd_call_term_type=pstn}" ..
                    "sofia/outbound_5060/%s@%s",
                    new_uuid, "pstn",
                    tonumber( pstnAnswerTimeout ),
                    tostring( appData.to_address ), tostring( cops_tt ) )

                -- appData.to_addresses[1] = appData.to_address

                createComboObString()
            else
                fsLogError( "*******  IN Error (Else) case for making a call *****" )
                playCallNotAllowed()
            end
        
            fsLogError( "*******  DOING ORIGINATE " .. obSessionString .." *****" )
            api:executeString("originate " .. obSessionString  .. " &park")

        else
            fsLogError( "*******  Manditory JSON value allow_call not returned or not 1 *****" )
        end

 



    end
end






fsLogInfo( "*******  END of onConfAdd.lua  *****" )
