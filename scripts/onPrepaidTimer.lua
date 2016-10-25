--               ____                       _     _ _____ _                     
--    ___  _ __ |  _ \ _ __ ___ _ __   __ _(_) __| |_   _(_)_ __ ___   ___ _ __ 
--   / _ \| '_ \| |_) | '__/ _ \ '_ \ / _` | |/ _` | | | | | '_ ` _ \ / _ \ '__|
--  | (_) | | | |  __/| | |  __/ |_) | (_| | | (_| | | | | | | | | | |  __/ |   
--   \___/|_| |_|_|   |_|  \___| .__/ \__,_|_|\__,_| |_| |_|_| |_| |_|\___|_|   
--                             |_|                                              
-- API BASED
-- wget --quiet -O - http://www.lemoda.net/games/figlet/figlet.cgi?text=onPrepaidTimer
--
api = freeswitch.API()
json = require('json')

-- ****  uuid_simplify   *** DO THIS IF WE CAN

-- ==========================================================
-- Initialize Variables STATIC
-- ==========================================================

modName = "onPrepaidTimer"

myUuid = argv[1]

fsd_schedule_seconds = api:executeString("uuid_getvar " .. myUuid .. " fsd_schedule_seconds" );

answeredNumber 		    = api:executeString("uuid_getvar " .. myUuid .. " destination_number");
toTN 			        = api:executeString("uuid_getvar " .. myUuid .. " fsd_toTN");
fromTN 			        = api:executeString("uuid_getvar " .. myUuid .. " fsd_fromTN");
basePrepaidTimerURL     = api:executeString("uuid_getvar " .. myUuid .. " fsd_on_prepaid_timer_uri");
timerTime 		        = api:executeString("uuid_getvar " .. myUuid .. " fsd_on_prepaid_timer_time")

logToDisk               = api:executeString("uuid_getvar " .. myUuid .. " fsd_logToDisk")
debug                   = api:executeString("uuid_getvar " .. myUuid .. " fsd_debug")

customerName            = api:executeString("uuid_getvar " .. myUuid .. " fsd_customer_name")

uuid_exists            = api:executeString("uuid_exists " .. myUuid );


-- ==========================================================
-- Shared Logging and Helper Functions 
--  Set modName, myUuid and debugUuid BEFORE this!!
-- ==========================================================
dofile("/etc/freeswitch/scripts/logAndHelper.lua")

-- ==========================================================
-- Main
-- ==========================================================

fsLogInfo( "*******  START of onPrepaidTimer.lua  *****" )

if uuid_exists then    -- This is just so I can intent and have it make since to indent :) 


    -- fsLogDebug( api:executeString('uuid_dump ' .. myUuid ));


	-- -----------------------------------------------------------------------
	-- Send Data to Server and get JSON response 
	-- -----------------------------------------------------------------------

        local postData = "to=" .. url_encode( "+" .. toTN )
		.. "&from=" .. url_encode( fromTN ) 
		.. "&uuid=" .. url_encode( myUuid ) 
		.. "&answeredNumber=" .. url_encode( answeredNumber ) 

	fsLogWarn( "** " .. basePrepaidTimerURL .. " post " .. postData )

        post_response = api:execute("curl", basePrepaidTimerURL .. " post " .. url_encode(postData ))
	fsLogDebug( " post_response = " .. post_response )


    if isErr( post_response ) then

        -- -----------------------------------------------------------------------
        -- If curl response starts with -ERR
        -- -----------------------------------------------------------------------

        fsLogError( string.format("*******  post_response  ERROR: %s  ********",
            tostring( post_response ) ))
        api:executeString("uuid_kill " .. fsd_uuid .. " CALL_REJECTED" )
        timerTime = 0  -- this is so we do not try to reschedule!!

    else

        appData = json.decode( post_response )

        -- Print out the JSON data we got back

        fsLogDebug( "\n----- appData Before Processing ------\n" ..  to_string( appData ) .. "\n--------------------------");

        -- -----------------------------------------------------------------------
        -- MANDITORY DATA
        --    Kill Call if allow_call == 0
        -- -----------------------------------------------------------------------

        -- If appData.allow_call is null (not given) then set it to 0 == kill the call
        local myAllow_call = ( appData.allow_call ~= nil ) and appData.allow_call or 0

        api:executeString("uuid_setvar " .. myUuid .. " fsd_allow_call " .. tostring( appData.allow_call ) )

        if myAllow_call == 0 then

            fsLogError( "===>  allow_call set to (" .. tostring( appData.allow_call ) 
                .. ") in onPrepaidTimer.lua -- doing uuid_kill ! " )

            fsLogInfo( "* YOU RAN OUT OF TIME ... PLAYING PROMPT and doing uuid_kill ***" );

            if appData.goodbye_prompt ~= nil then

                promptLocation = api:execute("http_get", appData.goodbye_prompt )
                api:executeString("uuid_broadcast " .. myUuid .. " " 
                    .. promptLocation ..  " both" )  -- Replace with real prompt
            else
                -- play this prompt because one was not provided
                api:executeString("uuid_broadcast " .. myUuid .. 
                    " voicemail/8000/vm-goodbye.wav both" )  -- Replace with real prompt
            end

            freeswitch.msleep(3000);  -- Wait for prompts to finish
            fsLogInfo( "*** YOU SHOULD HAVE HEARD A PROMPT ... BYE BYE NOW ***" );
            api:executeString("uuid_kill " .. myUuid )  -- kill leg

            timerTime = 0  -- this is so we do not try to reschedule!!
        end

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
            api:executeString("uuid_setvar " .. myUuid .. " fsd_on_prepaid_timer_uri " .. tostring( appData.on_prepaid_timer_uri ) )
        else
            fsLogInfo( "** on_prepaid_timer_uri not provided so not changing it." )
        end

        if appData.on_call_end_uri ~= nil then
            api:executeString("uuid_setvar " .. myUuid .. " fsd_on_call_end_uri " .. tostring( appData.on_call_end_uri ) )
        else
            fsLogInfo( "** on_call_end_uri not provided so not changing it." )
        end

        if appData.call_timeout ~= nil then
            fsLogInfo( "** call_timeout re-schedule for " .. appData.call_timeout .. " seconds .. starting from now" )
            api:executeString("sched_del " .. myUuid .. "_HUP" )
            api:executeString("sched_api +" .. appData.call_timeout .." " .. myUuid .. "_HUP hupall ALLOTTED_TIMEOUT fsd_uuid " .. myUuid )
        end

    end
else

    fsLogInfo( "==> That UUID is dead! !" )
    timerTime = 0  -- this is so we do not try to reschedule!!
end


if timerTime then    -- This means it is not nil
	if ( tonumber( timerTime ) ~= 0 ) then  -- If NOT 0 then do prepaid stuff
		
		timerTime = ( tonumber( timerTime ) >= 5 ) and timerTime or 5  -- If timerTime is <6, set it to 6
		fsLogInfo( "==> prepaid timer set to " .. timerTime .. " !" )

		-- -----------------------------------------------------------------------
		-- The next line is the FS magic that calls onPrepaidTimer.lua in (x) seconds
		-- -----------------------------------------------------------------------

		api:executeString("sched_api +" .. timerTime .." " .. myUuid .. " lua /etc/freeswitch/scripts/onPrepaidTimer.lua " .. myUuid )

	else   -- This is 0 - do NOT do prepaid stuff
		fsLogInfo( "==> NOT doing prepaid because timer set to 0 !" )
	end

else
	fsLogError( "====>  timerTime was nil -- we do not like that! Not doing prepaid stuff! " )
end

fsLogInfo( "*******  END of onPrepaidTimer.lua  *****" )
