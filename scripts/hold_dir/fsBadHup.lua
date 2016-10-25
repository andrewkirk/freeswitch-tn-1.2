-- fsHupTest - figlet
--   __     _   _           _____         _
--  / _|___| | | |_   _ _ _|_   _|__  ___| |_
-- | |_/ __| |_| | | | | '_ \| |/ _ \/ __| __|
-- |  _\__ \  _  | |_| | |_) | |  __/\__ \ |_
-- |_| |___/_| |_|\__,_| .__/|_|\___||___/\__|
--                     |_|
--
-- API BASED
--
api = freeswitch.API()

local myUuid, logLevel, modName

myUuid = session:getVariable("uuid")
gogiiHangupUUID = session:getVariable("gogiiHangupUUID")
hangup_cause = session:getVariable("hangup_cause")
fail_on_single_reject = tostring( session:getVariable("fail_on_single_reject") )

logLevel = "ERR"
modName = "BAD HANG UP (fsBadHup) "

function fsLog( logString )
	freeswitch.consoleLog(logLevel, 
		"\n** " ..  modName .. " uuid=" .. myUuid .. 
		"\n" .. logString .. "\n\n" )
end

-- session:execute("info")

-- --------------------------------------------
--  If Hangup Cause is one of the 'fail_on_single_reject' but NOT 'LOSE_RACE'
--   then kill all calls.  This kills calls in other threads too!
-- --------------------------------------------

if ( ( fail_on_single_reject:match(hangup_cause) ~= nil) and ( hangup_cause ~= "LOSE_RACE") ) then
	fsLog("== BAD HUP == match YES (hupall) ==" )
	-- fsLog("== BAD HUP == match YES (hupall) == '" .. fail_on_single_reject .. "' contains '" .. hangup_cause  .. "' and not LOSE_RACE")
	api:executeString("hupall " .. hangup_cause .. " gogiiHangupUUID " .. gogiiHangupUUID )
else
	fsLog("== BAD HUP == match NO ==" )
	-- fsLog("== BAD HUP == match NO == '" .. fail_on_single_reject .. "' does not contain '" .. hangup_cause .. "'" )
end

