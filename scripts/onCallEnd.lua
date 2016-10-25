--              ____      _ _ _____           _ 
--  ___  _ __  / ___|__ _| | | ____|_ __   __| |
-- / _ \| '_ \| |   / _` | | |  _| | '_ \ / _` |
--| (_) | | | | |__| (_| | | | |___| | | | (_| |
-- \___/|_| |_|\____\__,_|_|_|_____|_| |_|\__,_|
--                                              
-- wget --quiet -O - http://www.lemoda.net/games/figlet/figlet.cgi?text=onCallEnd
-- SESSION BASED
--
api = freeswitch.API()
json = require('json')

-- ****  uuid_simplify   *** DO THIS IF WE CAN

-- ==========================================================
-- Initialize Variables STATIC
-- ==========================================================

modName = "onCallEnd"

myUuid 			    = session:getVariable("uuid")
debugUuid     		= session:getVariable("fsd_conf_uuid")
answeredNumber 		= session:getVariable("destination_number");
toTN 			    = session:getVariable("fsd_toTN");
fromTN 			    = session:getVariable("fsd_fromTN");

logToDisk           = session:getVariable("fsd_logToDisk")
debug               = session:getVariable("fsd_debug")
logFileUrl          = session:getVariable("fsd_logFileUrl")

-- ==========================================================
-- Shared Logging and Helper Functions 
-- ==========================================================
dofile("/etc/freeswitch/scripts/logAndHelper.lua")

-- ==========================================================
-- Main 
-- ==========================================================

	fsLogInfo( "*******  START of onCallEnd.lua  *****" )

	-- session:execute("info")  -- print all channel variable on fs_cli console
    -- fsLogDebug( api:executeString('uuid_dump ' .. myUuid )); 

	local callID = session:getVariable("sip_call_id");

	origDisp = session:getVariable("originate_disposition");

	-- origDisp will be nil if call was successful
	callSuccess = (origDisp == "SUCCESS" ) and 1 or 0

	fsLogDebug(" ========== Originate Disposistion = " .. tostring(origDisp)
		.. " success = " .. callSuccess .. "")

	baseOnCallEndURL = session:getVariable("fsd_on_call_end_uri" )

	local postData = "to=" .. url_encode( "+" .. tostring( session:getVariable("fsd_toTN" ) ))  
		.. "&from=" .. url_encode( tostring( session:getVariable("fsd_fromTN" ) ))
        .. "&answered=" .. url_encode( tostring( session:getVariable("fsd_answeredTN")))
		.. "&uuid=" .. url_encode( myUuid )
		.. "&source=" .. url_encode( tostring( session:getVariable("fsd_call_orig_type" ) ))
		.. "&termStatus=" ..  url_encode( tostring( session:getVariable("sip_term_status") ))
		.. "&hangupCause=" ..  url_encode( tostring( session:getVariable("hangup_cause") ))
		.. "&callDuration=" .. url_encode( tostring( session:getVariable("billsec") ))
		.. "&vmLocation=" ..  url_encode( tostring( session:getVariable("fsd_vmLocation")) )
		.. "&origSipToUri=" .. url_encode( session:getVariable("sip_to_uri") )
		.. "&origSipFromUri=" .. url_encode( session:getVariable("sip_from_uri") )
		.. "&origSipCallId=" .. url_encode( session:getVariable("sip_call_id") )
		.. "&termSipToUri=" .. url_encode( session:getVariable("fsd_term_sip_to_uri") )
		.. "&termSipFromUri=" .. url_encode( session:getVariable("fsd_term_sip_from_uri") )
		.. "&termSipCallId=" .. url_encode( session:getVariable("fsd_term_sip_call_id") )
		.. "&customer=" .. url_encode( session:getVariable("fsd_customer_name") )
		.. "&confUuid=" .. url_encode( session:getVariable("fsd_conf_uuid") )

		-- .. "&startTime=" ..  session:getVariable("start_epoch")
		-- .. "&answerTime=" ..  session:getVariable("answer_epoch")
		-- .. "&bridgeTime=" ..  session:getVariable("bridge_epoch")
		-- .. "&endTime=" ..  session:getVariable("end_epoch")


    if logFileUrl ~= nil and logFileUrl ~= "" and toBoolean( debug) and toBoolean( logToDisk ) then
        postData = postData .. "&logFileUrl=" .. url_encode( tostring( logFileUrl ) )
    end

	fsLogWarn( "** " .. baseOnCallEndURL .. " post " .. postData )

	post_response = api:execute("curl", baseOnCallEndURL .. " post " .. url_encode(postData) )
	fsLogDebug( " post_response = " .. post_response )

	-- session:execute("curl", baseOnCallEndURL .. " post " .. postData )
	-- session:execute("curl", baseOnCallEndURL .. "?" .. postData )  -- Need GET for internal fs-http servers

	-- curl_response_code = session:getVariable("curl_response_code")
	-- curl_response      = session:getVariable("curl_response_data")

	-- fsLogWarn( " curl_response_code = " .. curl_response_code )
	-- fsLogWarn( " curl_response = " .. curl_response )


fsLogInfo( "*******  END of onCallEnd.lua  *****" )

