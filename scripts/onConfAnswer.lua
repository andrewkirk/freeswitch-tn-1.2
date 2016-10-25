--               ____             __   _                                
--   ___  _ __  / ___|___  _ __  / _| / \   _ __  _____      _____ _ __ 
--  / _ \| '_ \| |   / _ \| '_ \| |_ / _ \ | '_ \/ __\ \ /\ / / _ \ '__|
-- | (_) | | | | |__| (_) | | | |  _/ ___ \| | | \__ \\ V  V /  __/ |   
--  \___/|_| |_|\____\___/|_| |_|_|/_/   \_\_| |_|___/ \_/\_/ \___|_|   
--                                                                      
--
-- This LUA Code is done ONCE right after outbound call is made
-- wget --quiet -O - http://www.lemoda.net/games/figlet/figlet.cgi?text=onConfAnswer
-- 
-- SESSION BASED
--

api = freeswitch.API()
json = require('json')

-- ****  uuid_simplify   *** DO THIS IF WE CAN

-- ==========================================================
-- Initialize Variables STATIC
-- ==========================================================

modName = "onConfAnswer"


logToDisk               = session:getVariable("fsd_logToDisk")
debug                   = session:getVariable("fsd_debug")

myUuid 			        = session:getVariable("uuid")
fsd_uuid 			    = session:getVariable("fsd_uuid")
debugUuid        		= session:getVariable("fsd_conf_uuid")
answeredNumber 		    = session:getVariable("destination_number");
toTN 			        = session:getVariable("fsd_toTN");
fromTN 			        = session:getVariable("fsd_fromTN");
baseOnAnswerURL 	    = session:getVariable("fsd_on_conf_answer_uri");
timerTime 		        = session:getVariable("fsd_on_prepaid_timer_time")
fsd_call_term_type 		= session:getVariable("fsd_call_term_type")
fsd_conf_uuid     		= session:getVariable("fsd_conf_uuid")
call_timeout            = session:getVariable("fsd_call_timeout")
customerName            = session:getVariable("fsd_customer_name")

fsd_term_sip_call_id	= session:getVariable("sip_call_id")
fsd_term_sip_to_uri	    = session:getVariable("sip_to_uri")
fsd_term_sip_from_uri	= session:getVariable("sip_from_uri")

api:executeString("uuid_setvar " .. fsd_uuid .. " fsd_answeredTN " .. answeredNumber )
api:executeString("uuid_setvar " .. fsd_uuid .. " fsd_call_term_type " .. fsd_call_term_type )
api:executeString("uuid_setvar " .. fsd_uuid .. " fsd_term_sip_call_id " .. fsd_term_sip_call_id )
api:executeString("uuid_setvar " .. fsd_uuid .. " fsd_term_sip_to_uri " .. fsd_term_sip_to_uri )
api:executeString("uuid_setvar " .. fsd_uuid .. " fsd_term_sip_from_uri " .. fsd_term_sip_from_uri )


-- ==========================================================
-- Shared Logging and Helper Functions 
--  Set modName, myUuid and debugUuid BEFORE this!!
-- ==========================================================
dofile("/etc/freeswitch/scripts/logAndHelper.lua")


-- ==========================================================
-- Main
-- ==========================================================

if true then    -- This is just so I can intent this as a block

	fsLogInfo( "*******  START of onConfAnswer.lua  *****" )

    -- session:execute("info")
    fsLogDebug( api:executeString('uuid_dump ' .. myUuid )); 

	-- -----------------------------------------------------------------------
	-- Send Data to Server and get JSON response 
	-- -----------------------------------------------------------------------

	local postData = "to=" .. url_encode( toTN ) 
		.. "&from=" .. url_encode( fromTN ) 
		.. "&uuid=" .. url_encode( fsd_uuid ) 
		.. "&answeredNumber=" .. url_encode( answeredNumber ) 
		.. "&termSipToUri=" .. url_encode( fsd_term_sip_to_uri )
		.. "&termSipFromUri=" .. url_encode( fsd_term_sip_from_uri )
		.. "&termSipCallId=" .. url_encode( fsd_term_sip_call_id )
		.. "&customer=" .. url_encode( customerName )

	fsLogWarn( string.format("\n----------------------\n %s post %s\n------------------------", 
        baseOnAnswerURL, postData ))

	session:execute("curl", baseOnAnswerURL .. " post " .. postData )

	curl_response_code = session:getVariable("curl_response_code")
	curl_response      = session:getVariable("curl_response_data")


    if curl_response_code == "200" then
        appData = json.decode( curl_response )
    end


    if curl_response_code ~= "200" then

        -- -----------------------------------------------------------------------
        -- If curl response code is not 200, then play "bad" prompt and hangup
        -- -----------------------------------------------------------------------

        fsLogError( string.format("*******  curl_response_code ERROR: %s  Message: %s ********",
            tostring( curl_response_code), tostring(curl_response) ))
        api:executeString("uuid_kill " .. fsd_uuid .. " CALL_REJECTED" )

    elseif appData.error_code ~= nil then

        -- -----------------------------------------------------------------------
        -- If Error_code is returned, then play "bad" prompt and hangup
        -- -----------------------------------------------------------------------

        fsLogError( string.format("*******  appData.error_code ERROR: %s  Message: %s ********",
            tostring( appData.error_code), tostring(appData.message) ))
        api:executeString("uuid_kill " .. fsd_uuid .. " CALL_REJECTED" )

    else

        fsLogDebug( "\n-----onConfAnswer appData Before Processing ------\n" ..  to_string( appData ) .. "\n--------------------------");


        -- -----------------------------------------------------------------------
        -- Required Data
        -- -----------------------------------------------------------------------

        if appData.allow_call == nil or appData.allow_call == 0 then
                fsLogError( "===>  allow_call set to 0 in onConfAnswer.lua -- doing session:hangup ! " )
                api:executeString("uuid_kill " .. fsd_uuid .. " CALL_REJECTED" )
        else

            session:setVariable("fsd_allow_call", 	appData.allow_call )

            -- -----------------------------------------------------------------------
            -- Optional Data - Check or set defaults
            -- -----------------------------------------------------------------------

            if appData.on_prepaid_timer_time ~= nil then

                if appData.on_prepaid_timer_time == 0  then
                    -- leave it at 0
                else
                    appData.on_prepaid_timer_time = appData.on_prepaid_timer_time >= 5 and appData.on_prepaid_timer_time or 5;
                end 
                api:executeString("uuid_setvar " .. myUuid .. " fsd_on_prepaid_timer_time " .. tostring( appData.on_prepaid_timer_time ) )
                timerTime = appData.on_prepaid_timer_time
                
            else
                fsLogDebug( "fsd_on_prepaid_timer_time not set .. using default value" )
            end

            if appData.on_prepaid_timer_uri ~= nil then
                session:setVariable("fsd_on_prepaid_timer_uri", 	appData.on_prepaid_timer_uri )
            else
                fsLogInfo( "** on_prepaid_timer_uri not provided so not changing it." )
            end

            if appData.on_call_end_uri ~= nil then
                session:setVariable("fsd_on_call_end_uri", 	appData.on_call_end_uri )
            else
                fsLogInfo( "** on_call_end_uri not provided so not changing it." )
            end

            if appData.call_timeout ~= nil then
                fsLogInfo( "** RESCHEDULE TIME: call_timeout re-schedule for " .. appData.call_timeout .. " seconds .. starting from now" )
                api:executeString("sched_del " .. fsd_uuid .. "_HUP" )
                api:executeString("sched_api +" .. appData.call_timeout .." " .. fsd_uuid .. "_HUP hupall ALLOTTED_TIMEOUT fsd_uuid " .. fsd_uuid )
            else
                -- -----------------------------------------------------------------------
                -- Set the call to die after XX seconds .. unless the timer is updated
                -- -----------------------------------------------------------------------

                fsLogInfo( "** FIRST TIME: call_timeout schedule for " .. call_timeout .. " seconds .. starting from now" )
                api:executeString("sched_del " .. fsd_uuid .. "_HUP" )
                api:executeString("sched_api +" .. call_timeout .." " .. fsd_uuid .. "_HUP hupall ALLOTTED_TIMEOUT fsd_uuid " .. fsd_uuid )

            end

            if timerTime then    -- This means it is not nil
                if ( tonumber( timerTime ) ~= 0 ) then  -- If NOT 0 then do prepaid stuff
                    
                    timerTime = ( tonumber( timerTime ) >= 5 ) and timerTime or 5  -- If timerTime is <6, set it to 6
                    fsLogInfo( "==> prepaid timer set to " .. timerTime .. " !" )

                    -- -----------------------------------------------------------------------
                    -- The next line is the FS magic that calls onPrepaidTimer.lua in (x) seconds
                    -- -----------------------------------------------------------------------

                    api:executeString("sched_api +" .. timerTime .." " .. fsd_uuid .. " lua /etc/freeswitch/scripts/onPrepaidTimer.lua " .. fsd_uuid )

                else   -- This is 0 - do NOT do prepaid stuff
                    fsLogInfo( "==> NOT doing prepaid because timer set to 0 !" )
                end

            else
                fsLogInfo( "====>  timerTime was nil -- we do not like that! Not doing prepaid stuff! " )
            end

            -- -----------------------------------------------------------------------
            -- Send the call into the conference bridge
            -- -----------------------------------------------------------------------

            local trnferStr = "uuid_transfer " .. myUuid .. " conf_" .. fsd_conf_uuid .. " XML enflick";

            fsLogDebug( "\n----- TRANSFER  New leg into Conference  ------\n" 
            ..  to_string( trnferStr ) 
            .. "\n--------------------------");

            api:executeString( trnferStr );

        end

    end

end


fsLogInfo( "*******  END of onConfAnswer.lua  *****" )


